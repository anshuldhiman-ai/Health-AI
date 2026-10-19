import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/scan/presentation/scan_result_sheet.dart';
import 'package:app/l10n/app_localizations.dart';

/// Camera capture screen per ref_ui.png (the nav-shell centre button).
///
/// The real camera preview + capture pipeline lands in M2 on the
/// inference isolate; what exists now is the full-screen shell so the
/// navigation and the result-sheet flow are complete end to end.
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key, this.mealKind = MealKind.lunch});

  /// The meal the user is logging into (from the route query), so the
  /// result sheet's confirm button says the right thing.
  final MealKind mealKind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.x4,
          ),
          child: Column(
            spacing: AppSpacing.x4,
            children: [
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    l10n.scanScreenTitle,
                    style: text.titleMedium,
                  ),
                  const Spacer(),
                  // Mirror the close button so the title is centred.
                  const SizedBox(width: 48),
                ],
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadii.sheet.x),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: AppSpacing.x3,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: scheme.primary,
                      ),
                      Text(
                        l10n.pointAtPlate,
                        style: text.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.cameraPlaceholder,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.x8,
                children: [
                  // Gallery pick (image_picker lands with M2 camera
                  // work; keep the affordance visible but inert).
                  IconButton.filledTonal(
                    onPressed: () {}, // TODO(M2): image_picker
                    icon: const Icon(Icons.photo_outlined),
                    iconSize: 24,
                  ),
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: FloatingActionButton(
                      elevation: 4,
                      focusElevation: 4,
                      hoverElevation: 6,
                      highlightElevation: 8,
                      onPressed: () => _openResultSheet(context),
                      child: const Icon(Icons.camera, size: 28),
                    ),
                  ),
                  // Mirror the left button so the title is centred.
                  const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openResultSheet(BuildContext context) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      // Shape comes from bottomSheetTheme (AppRadii.sheet = 24).
      builder: (_) => const ScanResultSheet(mealKind: MealKind.lunch),
    );
    // A confirmed add closes the whole scan flow back to the caller;
    // a plain dismissal stays here in "camera" (undo lives in the
    // snack bar).
    if (added == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
