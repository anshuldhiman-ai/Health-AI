import 'dart:async';

import 'package:flutter/material.dart';

/// The app's transient confirmation, with an optional single action.
///
/// Use this instead of calling [ScaffoldMessenger.showSnackBar] directly.
/// It exists because the framework's own auto-dismiss is not usable as a
/// contract:
///
///  * The messenger schedules its dismissal timer inside its `build`,
///    which makes "does it go away?" impossible to pin in a widget test
///    and leaves the answer to timing we do not control. Here the timer
///    is ours, so dismissal is deterministic and covered by a test.
///  * Showing a toast **replaces** the current one immediately rather
///    than queueing behind it, so a second confirmation can never stack
///    up and read as an overlay that is stuck.
///  * Acting on the toast closes it. An Undo that leaves its own
///    confirmation on screen is the specific bug this replaces.
///
/// The toast renders through the ambient [SnackBarThemeData], so shape,
/// colour and typography still come from design tokens.
abstract final class AppToast {
  /// Shows [message] and returns a handle that can end it early.
  ///
  /// Takes the [messenger] rather than a context: callers show a toast
  /// right after popping their own route, and looking the messenger up
  /// from a context that is on its way out is exactly the bug
  /// `use_build_context_synchronously` warns about.
  ///
  /// [onAction] runs after the toast is dismissed, so the action's own
  /// side effects (undoing a write, navigating) are never covered by a
  /// toast still animating out.
  static AppToastHandle show(
    ScaffoldMessengerState messenger, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Retire whatever is up before touching the messenger: it cancels
    // that toast's timer, so a superseded toast can never come back and
    // close the one that replaced it.
    _live?.retire();

    // Replace, never queue. Removing outright rather than animating out
    // also means the new toast starts from a known state.
    messenger.removeCurrentSnackBar();

    final handle = AppToastHandle._();
    _live = handle;
    handle._controller = messenger.showSnackBar(
      SnackBar(
        duration: duration,
        content: Text(message),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                onPressed: () {
                  handle.close();
                  onAction?.call();
                },
              ),
      ),
    );
    handle._timer = Timer(duration, handle.close);
    return handle;
  }

  /// The toast currently on screen, if any.
  ///
  /// A single slot mirrors the messenger's own behaviour, and it is what
  /// lets a superseded toast's timer be recognised as stale rather than
  /// allowed to close its replacement. It holds no app data.
  static AppToastHandle? _live;
}

/// Handle for one shown toast.
class AppToastHandle {
  AppToastHandle._();

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _controller;
  Timer? _timer;
  bool _closed = false;

  /// Whether this toast is still the one on screen.
  bool get isShowing => !_closed && identical(AppToast._live, this);

  /// Ends this toast early. A no-op once it has gone, or after a newer
  /// toast replaced it — closing then would dismiss the wrong one.
  void close() {
    if (!isShowing) return;
    _closed = true;
    AppToast._live = null;
    _timer?.cancel();
    _timer = null;
    _controller?.close();
  }

  /// Gives up this toast's claim on the screen without touching the
  /// messenger, for a toast that is being replaced (or is already gone).
  void retire() {
    _closed = true;
    _timer?.cancel();
    _timer = null;
    if (identical(AppToast._live, this)) AppToast._live = null;
  }
}
