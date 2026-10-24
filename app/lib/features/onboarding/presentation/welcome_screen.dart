import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/data/preferences/body_metrics_controller.dart';
import 'package:app/design_system/components/brand_mark.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/l10n/app_localizations.dart';

/// Welcome/onboarding aligned to ui_design.jpg & ui_design2.jpg:
/// - Step 0: Splash & Brand Mark with "Eat Smart. Live Healthier." tagline + "Get Started"
/// - Step 1: First-time Profile Setup: Name, optional Date of Birth, Height & Weight with
///   unit toggles (cm/ft, kg/lb), live color-coded BMI, and "Not sure? Add later" skip option.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _seenKey = 'welcome.seen.v1';
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  Timer? _launchTimer;
  bool _returning = false;
  int _currentStep = 0; // 0: Splash/Welcome, 1: Profile Setup

  // Profile Form Controllers
  final _nameController = TextEditingController(text: '');
  final _heightController = TextEditingController(text: '');
  final _weightController = TextEditingController(text: '');
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    _resolveReturningSession();
  }

  Future<void> _resolveReturningSession() async {
    var seen = false;
    try {
      seen = (await SharedPreferences.getInstance()).getBool(_seenKey) ?? false;
    } catch (_) {
      // Keep onboarding available if local preferences cannot be read.
    }
    if (!mounted || !seen) return;
    setState(() => _returning = true);
    _entrance.forward();
    _launchTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) context.go('/today');
    });
  }

  @override
  void dispose() {
    _launchTimer?.cancel();
    _entrance.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding({bool skipMeasurements = false}) async {
    try {
      final name = _nameController.text.trim();
      final h = double.tryParse(_heightController.text);
      final w = double.tryParse(_weightController.text);

      ref.read(bodyMetricsProvider.notifier).update(
        name: name.isNotEmpty ? name : 'Alex',
        dateOfBirth: _dob,
        heightCm: skipMeasurements || h == null
            ? null
            : (_heightUnit == 'ft' ? h * 30.48 : h),
        weightKg: skipMeasurements || w == null
            ? null
            : (_weightUnit == 'lb' ? w / 2.20462 : w),
        useFeet: _heightUnit == 'ft',
        useLbs: _weightUnit == 'lb',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, true);
    } catch (_) {
      // Keep navigation working even if preferences fail
    }

    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WelcomeBlobsPainter(
                sage: colors.primaryWash,
                cream: colors.accentWash,
                gold: colors.accentSoft.withValues(alpha: 0.22),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _currentStep == 0
                  ? _buildWelcomeStep(context, scheme, colors, l10n)
                  : _buildProfileSetupStep(context, scheme, colors, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep(
    BuildContext context,
    ColorScheme scheme,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          FadeTransition(
            opacity: _returning ? _entrance : const AlwaysStoppedAnimation(1),
            child: const BrandMark(size: 110),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            child: Text(
              _returning ? 'Welcome back' : l10n.appTitle,
              key: ValueKey(_returning),
              style: AppTypography.hero.copyWith(
                color: scheme.onSurface,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _returning
                ? 'Your daily wellness, beautifully in sync.'
                : 'Eat Smart. Live Healthier.\nOn-device AI nutrition tracking & wellness',
            style: AppTypography.bodyM.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          if (!_returning) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3E2E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.getStarted,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => _deviceOnlyNote(context),
              child: Text(
                '100% Free • Private & Offline',
                style: AppTypography.label.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            const SizedBox(height: 22),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileSetupStep(
    BuildContext context,
    ColorScheme scheme,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    // Real-time BMI Calculation
    final parsedH = double.tryParse(_heightController.text);
    final parsedW = double.tryParse(_weightController.text);
    final realHeightCm = parsedH != null
        ? (_heightUnit == 'ft' ? parsedH * 30.48 : parsedH)
        : null;
    final realWeightKg = parsedW != null
        ? (_weightUnit == 'lb' ? parsedW / 2.20462 : parsedW)
        : null;

    double? previewBmi;
    if (realHeightCm != null && realWeightKg != null && realHeightCm > 0) {
      previewBmi = realWeightKg / ((realHeightCm / 100) * (realHeightCm / 100));
    }

    final bmiColor = previewBmi == null
        ? scheme.onSurfaceVariant
        : previewBmi < 17.0
            ? const Color(0xFFEF4444) // Red: Underweight severe
            : previewBmi < 18.5
                ? const Color(0xFFEAB308) // Yellow: Underweight edge
                : previewBmi < 25.0
                    ? const Color(0xFF10B981) // Green: Healthy normal
                    : previewBmi < 30.0
                        ? const Color(0xFFEAB308) // Yellow: Overweight edge
                        : const Color(0xFFEF4444); // Red: Obese

    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => setState(() => _currentStep = 0),
            icon: const Icon(Icons.arrow_back_rounded),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalize Your Profile',
            style: AppTypography.hero.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your name and measurements help calculate your daily calories and BMI.',
            style: AppTypography.bodyM.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          // Name Field
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'What should we call you?',
              hintText: 'Enter your name (e.g., Alex)',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: scheme.surface,
            ),
          ),
          const SizedBox(height: 14),
          // Optional Date of Birth
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dob ?? DateTime(2000, 1, 1),
                firstDate: DateTime(1930),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dob = picked);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dob != null
                          ? 'Born: ${_dob!.day}/${_dob!.month}/${_dob!.year}'
                          : 'Date of Birth (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        color: _dob != null ? scheme.onSurface : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (_dob != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _dob = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    const Icon(Icons.calendar_today_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Height with Unit Selector
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Height ($_heightUnit)',
                    hintText: _heightUnit == 'cm' ? '175' : '5.9',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: scheme.surface,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cm', label: Text('cm')),
                  ButtonSegment(value: 'ft', label: Text('ft')),
                ],
                selected: {_heightUnit},
                onSelectionChanged: (val) => setState(() {
                  final next = val.first;
                  final parsed = double.tryParse(_heightController.text);
                  if (parsed != null) {
                    _heightController.text = (next == 'ft' ? parsed / 30.48 : parsed * 30.48)
                        .toStringAsFixed(1);
                  }
                  _heightUnit = next;
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Weight with Unit Selector
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Weight ($_weightUnit)',
                    hintText: _weightUnit == 'kg' ? '70' : '154',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: scheme.surface,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'kg', label: Text('kg')),
                  ButtonSegment(value: 'lb', label: Text('lb')),
                ],
                selected: {_weightUnit},
                onSelectionChanged: (val) => setState(() {
                  final next = val.first;
                  final parsed = double.tryParse(_weightController.text);
                  if (parsed != null) {
                    _weightController.text = (next == 'lb' ? parsed * 2.20462 : parsed / 2.20462)
                        .toStringAsFixed(1);
                  }
                  _weightUnit = next;
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Live calculated BMI Preview
          if (previewBmi != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bmiColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: bmiColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.monitor_weight_outlined, color: bmiColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated BMI: ${previewBmi.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: bmiColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          previewBmi < 17.0
                              ? 'Severely Underweight'
                              : previewBmi < 18.5
                                  ? 'Borderline Underweight'
                                  : previewBmi < 25.0
                                      ? 'Healthy / Normal Range'
                                      : previewBmi < 30.0
                                          ? 'Borderline Overweight'
                                          : 'Obese Range',
                          style: TextStyle(
                            color: bmiColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          // Continue Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _finishOnboarding(skipMeasurements: false),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F3E2E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Continue to Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Skip Option
          Center(
            child: TextButton(
              onPressed: () => _finishOnboarding(skipMeasurements: true),
              child: Text(
                'Not sure? Add later & skip for now',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deviceOnlyNote(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('100% Free & Private'),
        content: const Text(
          'Health AI is a completely free application with no paid subscriptions. '
          'All your health metrics and photos are processed locally on your phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBlobsPainter extends CustomPainter {
  const _WelcomeBlobsPainter({
    required this.sage,
    required this.cream,
    required this.gold,
  });

  final Color sage;
  final Color cream;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final sagePaint = Paint()
      ..color = sage
      ..style = PaintingStyle.fill;
    final sagePath = Path()
      ..moveTo(0, h * .15)
      ..cubicTo(w * .3, h * .05, w * .7, h * .22, w, h * .12)
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(sagePath, sagePaint);

    final creamPaint = Paint()
      ..color = cream
      ..style = PaintingStyle.fill;
    final creamPath = Path()
      ..moveTo(0, h * .82)
      ..cubicTo(w * .35, h * .75, w * .65, h * .88, w, h * .80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(creamPath, creamPaint);

    final goldPaint = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * .88, h * .38), w * .28, goldPaint);
  }

  @override
  bool shouldRepaint(covariant _WelcomeBlobsPainter old) =>
      old.sage != sage || old.cream != cream || old.gold != gold;
}
