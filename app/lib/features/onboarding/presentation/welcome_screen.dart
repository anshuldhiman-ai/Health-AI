import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/error/app_log.dart';
import 'package:app/data/local_storage.dart';
import 'package:app/app/router.dart';
import 'package:app/data/preferences/body_metrics_controller.dart';
import 'package:app/app/log_store.dart';
import 'package:app/data/preferences/water_controller.dart';
import 'package:app/data/preferences/sleep_controller.dart';
import 'package:app/design_system/components/brand_mark.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/l10n/app_localizations.dart';

/// Onboarding, first run only:
/// - Step 0: brand lockup, the offline/private promise, and "Get Started".
/// - Step 1: profile setup — name, optional date of birth, height and
///   weight with unit toggles, a live BMI preview, and a skip option.
///
/// The returning-user path is not a screen state: the router decides
/// once, from the state bootstrap already read, so a user who finished
/// onboarding never lands here again (see `router.dart`).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _seenKey = 'welcome.seen.v1';
  int _currentStep = 0; // 0: Welcome, 1: Profile setup

  // Profile form controllers.
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

  /// Belt and braces for a build where bootstrap could not read the
  /// seen-flag: if onboarding was already completed, leave immediately
  /// rather than showing the welcome page again.
  Future<void> _resolveReturningSession() async {
    var seen = false;
    try {
      seen = await AppLocalStorage.readBool(_seenKey) ?? false;
      final metrics = ref.read(bodyMetricsProvider);
      if (metrics.onboardingCompleted ||
          metrics.heightCm != null ||
          metrics.weightKg != null ||
          ref.read(dayLogProvider).values.any((l) => l.isNotEmpty) ||
          ref.read(waterProvider).glasses > 0 ||
          ref.read(sleepProvider).records.isNotEmpty) {
        seen = true;
      }
    } catch (e, s) {
      AppLog.record(e, s);
      // Keep onboarding available if local preferences cannot be read.
    }
    if (!mounted || !seen) return;
    markWelcomeSeen();
    if (mounted) context.go('/today');
  }

  @override
  void dispose() {
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

      final current = ref.read(bodyMetricsProvider);
      await ref
          .read(bodyMetricsProvider.notifier)
          .update(
            // An empty field stays empty and BodyMetrics keeps its own
            // default, so no name is invented here.
            name: name.isEmpty ? current.name : name,
            dateOfBirth: _dob ?? current.dateOfBirth,
            heightCm: skipMeasurements || h == null
                ? current.heightCm
                : (_heightUnit == 'ft' ? h * 30.48 : h),
            weightKg: skipMeasurements || w == null
                ? current.weightKg
                : (_weightUnit == 'lb' ? w / 2.20462 : w),
            useFeet: _heightUnit == 'ft',
            useLbs: _weightUnit == 'lb',
            onboardingCompleted: true,
          );

      await AppLocalStorage.writeBool(_seenKey, true);
      markWelcomeSeen();
    } catch (e, s) {
      AppLog.record(e, s);
      // Keep navigation working even if preferences fail.
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
    AppColorScheme colors,
    AppLocalizations l10n,
  ) {
    return LayoutBuilder(
      key: const ValueKey(0),
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // App Logo & Header: "Health AI" with green leaf
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BrandMark(size: 28),
                      const SizedBox(width: 8),
                      Text(
                        l10n.appTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1C1E),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3 Rounded Square Glassmorphic Cards Showcase
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GlassThumbnailBox(
                        icon: Icons.groups_rounded,
                        bgColor: const Color(0xFFE8F3EE),
                        iconColor: const Color(0xFF0F5A3C),
                        size: 64,
                      ),
                      const SizedBox(width: 14),
                      _GlassThumbnailBox(
                        icon: Icons.volunteer_activism_rounded,
                        bgColor: const Color(0xFF0F5A3C),
                        iconColor: Colors.white,
                        size: 82,
                        isElevated: true,
                      ),
                      const SizedBox(width: 14),
                      _GlassThumbnailBox(
                        icon: Icons.favorite_rounded,
                        bgColor: const Color(0xFFFDECEB),
                        iconColor: const Color(0xFFE55858),
                        size: 64,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Biometric Face ID Prompt Area
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF0F5A3C).withValues(alpha: 0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F5A3C).withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.face_unlock_rounded,
                          color: Color(0xFF0F5A3C),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Biometric Face ID',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C7278),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Onboarding Completion 85% Progress Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F5A3C).withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Onboarding Completion',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1C1E),
                              ),
                            ),
                            Text(
                              '85%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E885F),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const LinearProgressIndicator(
                            value: 0.85,
                            minHeight: 8,
                            backgroundColor: Color(0xFFE9F0EC),
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E885F)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Continue with Apple (Black Pill)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _currentStep = 1),
                      icon: const Icon(Icons.apple, size: 22, color: Colors.white),
                      label: const Text(
                        'Continue with Apple',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000000),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Continue with Google (White Pill with Subtle Shadow)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _currentStep = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A1C1E),
                        elevation: 0,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: const Color(0xFFE5E9EE).withValues(alpha: 0.9),
                          ),
                        ),
                        shadowColor: const Color(0xFF0F5A3C).withValues(alpha: 0.08),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4285F4),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1C1E),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sign in with Email / Get Started
                  TextButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    child: const Text(
                      'Sign in with Email or Get Started',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F5A3C),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Learn Facts / Learn about On-Device AI card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F5A3C).withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E885F).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                            color: Color(0xFF0F5A3C),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Learn Facts',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1C1E),
                                ),
                              ),
                              Text(
                                'Learn about On-Device AI & 100% Privacy',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6C7278),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF6C7278),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSetupStep(
    BuildContext context,
    ColorScheme scheme,
    AppColorScheme colors,
    AppLocalizations l10n,
  ) {
    // Live BMI preview while the fields are being typed.
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

    final (bmiColor, bmiLabel) = previewBmi == null
        ? (scheme.onSurfaceVariant, '')
        : _bmiBand(previewBmi, colors);

    return SingleChildScrollView(
      key: const ValueKey(1),
      // Keep the fields reachable with the keyboard open.
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => setState(() => _currentStep = 0),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48), // R14
            ),
          ),
          const SizedBox(height: 4),
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

          // Name
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'What should we call you?',
              hintText: 'Enter your name (e.g., Alex)',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),

          // Optional date of birth. The height below it is what the BMI and
          // calorie maths need; age only refines the estimate.
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
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        color: _dob != null
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (_dob != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _dob = null),
                      tooltip: 'Clear date of birth',
                      padding: EdgeInsets.zero,
                    )
                  else
                    const Icon(Icons.calendar_today_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Height with unit selector
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Height ($_heightUnit)',
                    hintText: _heightUnit == 'cm' ? '175' : '5.9',
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
                    _heightController.text =
                        (next == 'ft' ? parsed / 30.48 : parsed * 30.48)
                            .toStringAsFixed(1);
                  }
                  _heightUnit = next;
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weight with unit selector
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Weight ($_weightUnit)',
                    hintText: _weightUnit == 'kg' ? '70' : '154',
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
                    _weightController.text =
                        (next == 'lb' ? parsed * 2.20462 : parsed / 2.20462)
                            .toStringAsFixed(1);
                  }
                  _weightUnit = next;
                }),
              ),
            ],
          ),

          if (previewBmi != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.washOf(bmiColor, strength: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: bmiColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.monitor_weight_outlined,
                    color: bmiColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated BMI: ${previewBmi.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          bmiLabel,
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
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _finishOnboarding(skipMeasurements: false),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size.fromHeight(54),
              ),
              child: Text(
                'Continue to Dashboard',
                style: AppTypography.label.copyWith(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 6),
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

  /// BMI is a coarse screening band, not a diagnosis (R5), so the bands
  /// are described rather than named clinically — and a body measurement
  /// is never shown in an alarm colour (Section 9.4). The outer bands
  /// share the caution tone for the same reason.
  (Color, String) _bmiBand(double bmi, AppColorScheme colors) {
    if (bmi < 18.5) return (colors.warning, 'Below the healthy range');
    if (bmi < 25.0) return (colors.success, 'Healthy range');
    return (colors.warning, 'Above the healthy range');
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

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.colors,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final AppColorScheme colors;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.washOf(colors.primary, strength: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// The offline/private promise, tappable for the details.
class _PrivacyPill extends StatelessWidget {
  const _PrivacyPill({required this.colors, required this.onTap});

  final AppColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: colors.washOf(colors.primary, strength: 1.3),
      borderRadius: const BorderRadius.all(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(AppRadii.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48), // R14
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                '100% Free • Private & Offline',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
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

class _GlassThumbnailBox extends StatelessWidget {
  const _GlassThumbnailBox({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.size,
    this.isElevated = false,
  });

  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final double size;
  final bool isElevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isElevated ? 24 : 20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isElevated ? 0.4 : 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isElevated
                ? const Color(0xFF0F5A3C).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isElevated ? 24 : 12,
            offset: Offset(0, isElevated ? 8 : 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.48,
        ),
      ),
    );
  }
}
