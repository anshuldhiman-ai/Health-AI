import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app/design_system/components/app_toast.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/app/log_store.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/data/nutrition/dish_catalog.dart';
import 'package:app/features/scan/application/food_recognizer.dart';
import 'package:app/features/scan/application/scan_state.dart';
import 'package:app/features/scan/presentation/quick_add_sheet.dart';
import 'package:app/features/scan/presentation/code_scanner_sheet.dart';
import 'package:app/features/scan/presentation/scan_result_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Full-screen camera capture â†’ on-device recognition flow.
///
/// Capture never leaves the phone: the JPEG is decoded in an isolate,
/// run through the bundled LiteRT classifier, joined with the local
/// nutrition catalog, and shown in [ScanResultSheet]. Failures are
/// handled explicitly (no silent "success"): a missing model, an
/// unreadable photo, or no camera each show a recoverable message,
/// with the gallery as the fallback path.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({
    super.key,
    this.mealKind = MealKind.lunch,
    this.dayOffset = 0,
  });

  /// The meal the user is logging into (from the route query), so the
  /// result sheet's confirm button says the right thing.
  final MealKind mealKind;

  /// 0 = today, 1 = yesterday, ... Target selected in Diary.
  final int dayOffset;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _picker = ImagePicker();

  CameraController? _controller;
  Future<void>? _initializing;
  String? _cameraError;

  Uint8List? _pendingPhoto;
  bool _analyzing = false;
  bool _torchOn = false;
  bool _showSessionResults = false;
  int _cameraGeneration = 0;
  late MealKind _mealKind;

  /// Drives the viewfinder's breathing pulse while a capture is being
  /// analysed. Idle it sits at 0, so the brackets are still.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _mealKind = widget.mealKind;
    WidgetsBinding.instance.addObserver(this);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _initializing = _initCamera();
    // Drop whatever the last visit left in the provider, and do it after
    // the first frame so we are not mutating provider state during
    // initState. Until a scan completes in THIS visit, `session` stays
    // null and the camera shows no detection pills at all.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(scanSessionProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    ++_cameraGeneration;
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    final controller = _controller;
    _controller = null;
    unawaited(controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.inactive) {
      ++_cameraGeneration;
      if (controller == null || !controller.value.isInitialized) return;
      _controller = null;
      unawaited(controller.dispose());
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _initializing = _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final generation = ++_cameraGeneration;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no-camera', 'No camera found');
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted || generation != _cameraGeneration) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraError = null;
        _initializing = null;
      });
    } on CameraException catch (error) {
      if (!mounted || generation != _cameraGeneration) return;
      setState(() {
        _cameraError = error.description ?? error.code;
        _controller = null;
        _initializing = null;
      });
    } catch (error) {
      if (!mounted || generation != _cameraGeneration) return;
      setState(() {
        _cameraError = error.toString();
        _controller = null;
        _initializing = null;
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _analyzing) {
      return;
    }
    try {
      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      await _analyze(bytes);
    } on CameraException {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.scanPhotoFailed);
      }
    } catch (_) {
      if (mounted) _showError(AppLocalizations.of(context)!.scanPhotoFailed);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_analyzing) return;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null) return;
      await _analyze(await picked.readAsBytes());
    } catch (_) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.scanPhotoFailed);
      }
    }
  }

  Future<void> _analyze(Uint8List bytes) async {
    if (_analyzing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _analyzing = true;
      _pendingPhoto = bytes;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      _pulse.repeat(reverse: true);
    }

    try {
      final output = await ref.read(foodRecognizerProvider).recognize(bytes);

      // Non-food gate. Checked before the catalog is even loaded: a photo
      // of a keyboard must never reach a "Confirm & Add to Diary" button,
      // so there is nothing to build a session for.
      if (!output.isFood) {
        if (mounted) await _showNotFoodDialog();
        return;
      }

      final catalog = await ref.read(dishCatalogProvider.future);
      final session = scanSessionFrom(
        output: output,
        catalog: catalog,
        photo: bytes,
      );
      if (!mounted) return;
      ref.read(scanSessionProvider.notifier).state = session;
      setState(() => _showSessionResults = true);

      final added = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) =>
            ScanResultSheet(mealKind: _mealKind, dayOffset: widget.dayOffset),
      );
      if (!mounted) return;
      // Whether the user confirmed or swiped the sheet away, the
      // prediction is finished with. Leaving it set is what made a stale
      // dish appear as a detection pill on the next visit.
      ref.read(scanSessionProvider.notifier).state = null;
      _showSessionResults = false;
      if (added == true) {
        Navigator.of(context).pop();
      }
    } on ModelUnavailableException {
      if (mounted) _showError(l10n.scanModelMissing);
    } on RecognitionException {
      if (mounted) _showError(l10n.scanPhotoFailed);
    } catch (_) {
      if (mounted) _showError(l10n.scanPhotoFailed);
    } finally {
      if (mounted) {
        // Stop the pulse and park it at rest so the brackets are still
        // again. Leaving the controller running would keep a ticker alive
        // for as long as the camera is open, burning frames for an
        // animation nobody can see.
        _pulse.stop();
        _pulse.value = 0;
        setState(() {
          _analyzing = false;
          _pendingPhoto = null;
        });
      }
    }
  }

  /// "Not a food item": what happened, and the two things the user can
  /// do next. Deliberately not an error - the photo was fine, it just
  /// wasn't a dish.
  Future<void> _showNotFoodDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final searchManually = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.viewPaddingOf(sheetContext).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              // Glowing pulsing amber icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.no_food_rounded,
                  color: Color(0xFFD97706),
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Not a Food Item',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We couldn't recognize a meal in this photo. Make sure your dish is well-lit and placed in the center of the frame, or search our food catalog manually.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons with neon / glowing effects
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.38),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: const Text(
                    'Search Food Manually',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3E2E),
                    foregroundColor: const Color(0xFF34D399),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (searchManually != true || !mounted) return;
    context.pushReplacement(
      '/search?meal=${_mealKind.name}&day=${widget.dayOffset}',
    );
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setFlashMode(_torchOn ? FlashMode.off : FlashMode.torch);
      if (mounted) {
        setState(() => _torchOn = !_torchOn);
        unawaited(HapticFeedback.selectionClick());
      }
    } on CameraException {
      // Torch is optional; ignore unsupported devices.
    }
  }

  /// Quick add: pick a dish by name instead of by photo, then hand off to
  /// the dish detail screen to log it.
  Future<bool> _quickAdd({String? initialFoodName}) async {
    var manuallyAdded = false;
    final dishId = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => QuickAddSheet(
        initialFoodName: initialFoodName,
        onManualAdd: (name, kcal) async {
          await ref
              .read(dayLogProvider.notifier)
              .addAndSave(
                LogEntry.estimated(
                  mealKind: _mealKind,
                  dish: name,
                  kcal: kcal,
                  timeLabel: TimeOfDay.now().format(context),
                ),
                dayOffset: widget.dayOffset,
              );
          manuallyAdded = true;
        },
      ),
    );
    if (manuallyAdded && mounted) {
      Navigator.of(context).pop();
      return true;
    }
    if (dishId == null || !mounted) return false;
    // replace, not push: the camera has done its job and should not sit
    // in the back stack behind the food the user is about to log.
    context.pushReplacement(
      '/dish/${Uri.encodeComponent(dishId)}'
      '?meal=${_mealKind.name}&day=${widget.dayOffset}',
    );
    return true;
  }

  Future<void> _scanCode() async {
    final camera = _controller;
    _controller = null;
    ++_cameraGeneration;
    if (camera != null) await camera.dispose();
    if (!mounted) return;
    setState(() {
      _initializing = Future<void>.value();
      _torchOn = false;
    });
    final code = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      builder: (_) => const CodeScannerSheet(),
    );
    if (!mounted) return;
    if (code != null) {
      final navigated = await _quickAdd(
        initialFoodName: _foodNameFromCode(code),
      );
      if (!mounted || navigated) return;
    }
    _initializing = _initCamera();
    setState(() {});
  }

  String _foodNameFromCode(String code) {
    try {
      final decoded = jsonDecode(code);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['product_name', 'productName', 'name', 'food']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
      }
    } catch (_) {
      // Ordinary QR text and retail barcodes are handled below.
    }
    final displayCode = code.length > 30 ? '${code.substring(0, 30)}â€¦' : code;
    return 'Product $displayCode';
  }

  Future<void> _pickMeal() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<MealKind>(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                l10n.selectMeal,
                style: AppTypography.itemS.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
            for (final kind in MealKind.values)
              ListTile(
                leading: Icon(
                  _mealIcon(kind),
                  color: Theme.of(sheetContext).colorScheme.primary,
                ),
                title: Text(l10n.mealLabel(kind)),
                selected: kind == _mealKind,
                trailing: kind == _mealKind
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(kind),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _mealKind = selected);
    }
  }

  static IconData _mealIcon(MealKind kind) {
    switch (kind) {
      case MealKind.breakfast:
        return Icons.wb_sunny_outlined;
      case MealKind.lunch:
        return Icons.lunch_dining_outlined;
      case MealKind.dinner:
        return Icons.nightlight_outlined;
      case MealKind.snacks:
        return Icons.cookie_outlined;
    }
  }

  void _showError(String message) {
    AppToast.show(ScaffoldMessenger.of(context), message: message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dishCount = ref.watch(dishCountProvider);
    final session = ref.watch(scanSessionProvider);
    final controller = _controller;
    final initializing = _initializing != null && controller == null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            _CameraPreview(controller: controller)
          else if (initializing)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            _CameraErrorState(
              message: _cameraError ?? l10n.scanCameraUnavailableHint,
              onGallery: _pickFromGallery,
            ),
          // Subtle top and bottom scrims
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x99000000), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xCC000000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Golden Viewfinder Frame in the center per ui_design.jpg Screen 4 & ui_design2.jpg Screen 2
          Center(
            child: _GoldenViewfinder(pulse: _pulse, active: _analyzing),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                        semanticLabel: l10n.closeLabel,
                      ),
                      // "Settings" pill button from ui_design2.jpg
                      Material(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: _pickMeal,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.settings_outlined,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  l10n.mealLabel(_mealKind),
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.expand_more_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.qr_code_scanner_rounded,
                        onTap: _analyzing ? null : _scanCode,
                        semanticLabel: 'Scan QR code or food barcode',
                        size: 44,
                      ),
                      const SizedBox(width: 8),
                      _TorchButton(
                        on: _torchOn,
                        onTap: controller == null ? null : _toggleTorch,
                        onLabel: l10n.scanTorchOn,
                        offLabel: l10n.scanTorchOff,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // "Detectingâ€¦" status badge. Only while a capture is
                // actually being analysed â€” it used to sit on the screen
                // permanently, which read as "the app is looking at a
                // dish" before the user had taken a photo.
                if (_analyzing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CC18F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          l10n.scanDetecting,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Candidate detection pills. Only during an active scan, or
                // from the scan that just finished in this visit â€” the
                // session is cleared on entry and on sheet dismissal, so a
                // dish from an earlier visit can never appear here.
                if (_analyzing || (_showSessionResults && session != null))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_showSessionResults &&
                            session != null &&
                            session.topMatches.isNotEmpty)
                          for (
                            var i = 0;
                            i < session.topMatches.length && i < 3;
                            i++
                          )
                            _DetectionPill(
                              label: session.topMatches[i].label,
                              confidence: '${session.topMatches[i].percent}%',
                            ),
                        if (_analyzing)
                          _DetectionPill(
                            label: l10n.scanDetecting,
                            confidence: '',
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                // Bottom Shutter & Controls per Showcase 1 & 2 Screen 2
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      const Text(
                        'Capture Your Meal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Snap a photo or upload from gallery to get instant nutrition insights',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _RoundIconButton(
                                icon: Icons.photo_library_outlined,
                                onTap: _analyzing ? null : _pickFromGallery,
                                semanticLabel: l10n.scanPickFromGallery,
                                size: 52,
                              ),
                              const SizedBox(height: 4),
                              const Text('Gallery', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          _MetallicShutterButton(
                            enabled:
                                controller != null &&
                                controller.value.isInitialized &&
                                !_analyzing,
                            busy: _analyzing,
                            label: l10n.scanCapture,
                            onTap: _capture,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _RoundIconButton(
                                icon: Icons.qr_code_scanner_rounded,
                                onTap: _analyzing ? null : _scanCode,
                                semanticLabel: 'Quick Add / Barcode',
                                size: 52,
                              ),
                              const SizedBox(height: 4),
                              const Text('Packaged', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_analyzing)
            _AnalyzingOverlay(
              photo: _pendingPhoto,
              title: l10n.scanAnalyzing,
              hint: l10n.scanAnalyzingHint(dishCount),
            ),
        ],
      ),
    );
  }
}

/// Candidate detection pill matching ui_design.jpg Screen 4
class _DetectionPill extends StatelessWidget {
  const _DetectionPill({required this.label, required this.confidence});

  final String label;
  final String confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (confidence.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              confidence,
              style: const TextStyle(
                color: Color(0xFF4CC18F),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Golden Viewfinder Frame matching ui_design.jpg & ui_design2.jpg
///
/// The brackets breathe while [active]; at rest they are perfectly
/// still, so motion means "something is happening" rather than being
/// permanent decoration (Section 10.8).
class _GoldenViewfinder extends StatelessWidget {
  const _GoldenViewfinder({required this.pulse, required this.active});

  final Animation<double> pulse;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final t = active ? pulse.value : 0.0;
          return CustomPaint(
            painter: _GoldenBracketPainter(
              // 0.55 -> 1.0 opacity and a whisper of scale. Enough to
              // read as alive at arm's length without competing with the
              // camera preview.
              opacity: 0.55 + 0.45 * t,
              scale: 1.0 + 0.02 * t,
            ),
          );
        },
      ),
    );
  }
}

class _GoldenBracketPainter extends CustomPainter {
  const _GoldenBracketPainter({this.opacity = 1.0, this.scale = 1.0});

  final double opacity;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    const goldColor = Color(0xFFD4AF37);
    final paint = Paint()
      ..color = goldColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (scale != 1.0) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(scale);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    final w = size.width;
    final h = size.height;
    const arm = 36.0;
    const r = 16.0;

    // Top-left corner
    final tl = Path()
      ..moveTo(0, arm)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(arm, 0);
    canvas.drawPath(tl, paint);

    // Top-right corner
    final tr = Path()
      ..moveTo(w - arm, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, arm);
    canvas.drawPath(tr, paint);

    // Bottom-left corner
    final bl = Path()
      ..moveTo(0, h - arm)
      ..lineTo(0, h - r)
      ..quadraticBezierTo(0, h, r, h)
      ..lineTo(arm, h);
    canvas.drawPath(bl, paint);

    // Bottom-right corner
    final br = Path()
      ..moveTo(w - arm, h)
      ..lineTo(w - r, h)
      ..quadraticBezierTo(w, h, w, h - r)
      ..lineTo(w, h - arm);
    canvas.drawPath(br, paint);

    if (scale != 1.0) canvas.restore();
  }

  @override
  bool shouldRepaint(_GoldenBracketPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.scale != scale;
}

/// Flash / light toggle.
///
/// Deliberately not a [_RoundIconButton]: "is my light on?" has to be
/// answerable at a glance in a dark kitchen. When lit, the control fills
/// gold, shows the solid bolt, and carries a glow; when off it is the
/// same translucent chip as its neighbours. The state is carried by
/// fill, icon and glow together, never by colour alone (R14).
class _TorchButton extends StatelessWidget {
  const _TorchButton({
    required this.on,
    required this.onTap,
    required this.onLabel,
    required this.offLabel,
  });

  final bool on;
  final VoidCallback? onTap;
  final String onLabel;
  final String offLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      button: true,
      toggled: on,
      label: on ? offLabel : onLabel,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color: on
              ? const Color(0xFFD4AF37)
              : Colors.white.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: on
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                size: 24,
                color: on
                    ? const Color(0xFF121614)
                    : (enabled ? Colors.white : Colors.white38),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Metallic gradient glowing shutter button from ui_design2.jpg Screen 2
///
/// Presses physically: the disc scales down and darkens while held, and
/// a light haptic fires on tap, so the shutter confirms the press even
/// when the camera preview has not visibly changed yet (Section 10.8).
class _MetallicShutterButton extends StatefulWidget {
  const _MetallicShutterButton({
    required this.enabled,
    required this.busy,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final String label;
  final VoidCallback onTap;

  @override
  State<_MetallicShutterButton> createState() => _MetallicShutterButtonState();
}

class _MetallicShutterButtonState extends State<_MetallicShutterButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.enabled || widget.busy;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: interactive ? (_) => _setPressed(true) : null,
        onTapUp: interactive ? (_) => _setPressed(false) : null,
        onTapCancel: interactive ? () => _setPressed(false) : null,
        onTap: widget.enabled
            ? () {
                unawaited(HapticFeedback.mediumImpact());
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF34D399),
                  Color(0xFF0D5C3A),
                  Color(0xFF083C25),
                ],
              ),
              border: Border.all(color: const Color(0xFFD4AF37), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34D399)
                      .withValues(alpha: _pressed ? 0.15 : 0.4),
                  blurRadius: _pressed ? 8 : 18,
                  spreadRadius: _pressed ? 0 : 2,
                ),
              ],
            ),
            child: Center(
              child: widget.busy
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _pressed
                              ? const [Color(0xFF047857), Color(0xFF03543C)]
                              : const [Color(0xFF10B981), Color(0xFF047857)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final preview = controller.value.previewSize;
    if (preview == null) {
      return const ColoredBox(color: Colors.black);
    }
    // Portrait cover: previewSize is landscape-oriented on Android.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: preview.height,
          height: preview.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _CameraErrorState extends StatelessWidget {
  const _CameraErrorState({required this.message, required this.onGallery});

  final String message;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white70,
            size: 44,
          ),
          Text(
            l10n.scanCameraUnavailableTitle,
            textAlign: TextAlign.center,
            style: AppTypography.titleM.copyWith(color: Colors.white),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 19),
            label: Text(l10n.scanPickFromGallery),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Icon(
              icon,
              size: size * 0.5,
              color: onTap == null ? Colors.white38 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyzingOverlay extends StatelessWidget {
  const _AnalyzingOverlay({
    required this.photo,
    required this.title,
    required this.hint,
  });

  final Uint8List? photo;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF17211C),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 14,
            children: [
              if (photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.memory(
                    photo!,
                    width: 168,
                    height: 168,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.itemS.copyWith(color: Colors.white),
              ),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: Colors.white60,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
