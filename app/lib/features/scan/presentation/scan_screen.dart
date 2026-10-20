import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/data/nutrition/dish_catalog.dart';
import 'package:app/features/scan/application/food_recognizer.dart';
import 'package:app/features/scan/application/scan_state.dart';
import 'package:app/features/scan/presentation/scan_result_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Full-screen camera capture → on-device recognition flow.
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
    with WidgetsBindingObserver {
  final _picker = ImagePicker();

  CameraController? _controller;
  Future<void>? _initializing;
  String? _cameraError;

  Uint8List? _pendingPhoto;
  bool _analyzing = false;
  bool _torchOn = false;
  late MealKind _mealKind;

  @override
  void initState() {
    super.initState();
    _mealKind = widget.mealKind;
    WidgetsBinding.instance.addObserver(this);
    _initializing = _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    _controller = null;
    unawaited(controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      unawaited(controller.dispose());
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _initializing = _initCamera();
    }
  }

  Future<void> _initCamera() async {
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
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraError = null;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = error.description ?? error.code;
        _controller = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = error.toString();
        _controller = null;
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _analyzing) {
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

    try {
      final output = await ref.read(foodRecognizerProvider).recognize(bytes);
      final catalog = await ref.read(dishCatalogProvider.future);
      final session = scanSessionFrom(
        output: output,
        catalog: catalog,
        photo: bytes,
      );
      if (!mounted) return;
      ref.read(scanSessionProvider.notifier).state = session;

      final added = await showModalBottomSheet<bool>(
        context: context,
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
      if (added == true && mounted) {
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
        setState(() {
          _analyzing = false;
          _pendingPhoto = null;
        });
      }
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setFlashMode(_torchOn ? FlashMode.off : FlashMode.torch);
      if (mounted) setState(() => _torchOn = !_torchOn);
    } on CameraException {
      // Torch is optional; ignore unsupported devices.
    }
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          // Scrims instead of gradients (flat design language).
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: ColoredBox(color: Color(0x66000000)),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 190,
            child: ColoredBox(color: Color(0x66000000)),
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
                      const Spacer(),
                      Material(
                        color: Colors.white.withValues(alpha: 0.16),
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
                      const Spacer(),
                      _RoundIconButton(
                        icon: _torchOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        onTap: controller == null ? null : _toggleTorch,
                        semanticLabel: l10n.scanTorch,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 26),
                  child: Column(
                    children: [
                      Text(
                        l10n.pointAtPlate,
                        textAlign: TextAlign.center,
                        style: AppTypography.itemS.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _RoundIconButton(
                                icon: Icons.photo_library_outlined,
                                onTap: _analyzing ? null : _pickFromGallery,
                                semanticLabel: l10n.scanPickFromGallery,
                                size: 50,
                              ),
                            ),
                          ),
                          _ShutterButton(
                            enabled:
                                controller != null &&
                                controller.value.isInitialized &&
                                !_analyzing,
                            busy: _analyzing,
                            semanticLabel: l10n.scanCapture,
                            onTap: _capture,
                          ),
                          const Expanded(child: SizedBox()),
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
              hint: l10n.scanAnalyzingHint,
            ),
        ],
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

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.enabled,
    required this.busy,
    required this.semanticLabel,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled ? Colors.white : Colors.white38,
              width: 4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: enabled ? Colors.white : Colors.white38,
                shape: BoxShape.circle,
              ),
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: scheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.camera_alt_rounded,
                      color: scheme.primary,
                      size: 26,
                    ),
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
