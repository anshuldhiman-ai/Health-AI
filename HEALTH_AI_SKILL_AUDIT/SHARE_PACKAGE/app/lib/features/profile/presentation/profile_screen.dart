import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/preferences/body_metrics_controller.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/nutrition_targets.dart';
import 'package:app/features/profile/presentation/goal_sheet.dart';
import 'package:app/features/profile/presentation/help_sheet.dart';
import 'package:app/features/profile/presentation/settings_sheet.dart';
import 'package:app/l10n/app_localizations.dart';

/// Account & Profile screen matching ui_design.jpg Screen 11:
/// - Golden gradient top arc banner
/// - Center avatar with user's name
/// - Tappable, editable personal details (Age, Height, Weight, Activity Level)
/// - Color-coded automatic BMI indicator (Green = healthy, Yellow = edge, Red = under/over)
/// - Integrations (Apple Health, Garmin, Fitbit)
/// - Nutrition goal settings
/// - Help & Privacy (100% Free, Device-only)
/// - Fully responsive across all device dimensions
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalKindProvider);
    final metrics = ref.watch(bodyMetricsProvider);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          children: [
            // Brand header banner (seamlessly integrated, never jitters or
            // moves awkwardly). Emerald rather than a fixed gold: whatever
            // sits on it draws in onPrimary, so it holds on either theme.
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: colors.emeraldGradient,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    10,
                    AppSpacing.screenPadding,
                    24,
                  ),
                  child: Column(
                    children: [
                      // Top Nav Bar: Back and Settings
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: scheme.onPrimary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            tooltip: 'Back',
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => showSettingsSheet(context),
                            icon: Icon(
                              Icons.settings_outlined,
                              color: scheme.onPrimary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            tooltip: 'Settings',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Center Avatar
                      Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.onPrimary,
                                width: 3.5,
                              ),
                              // No shadow in dark mode: a black shadow is
                              // invisible there, so shadow() drops it.
                              boxShadow: colors.shadow(alpha: 0.15, blur: 10),
                            ),
                            child: ClipOval(
                              child: Container(
                                color: scheme.surface,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: scheme.onPrimary,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '100% Free',
                                style: TextStyle(
                                  color: scheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Profile details & cards
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                16,
                AppSpacing.screenPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    metrics.name,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleL.copyWith(
                      color: scheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Account dashboard',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Personal Details header with Edit button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Personal Details',
                        style: AppTypography.titleM.copyWith(
                          color: scheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _editProfile(context, ref, metrics),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Details'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 4-column card for Personal Details (Age, Height, Weight, Activity)
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    onTap: () => _editProfile(context, ref, metrics),
                    child: Row(
                      children: [
                        _DetailItem(
                          label: 'Age',
                          value: metrics.age != null ? '${metrics.age}' : '—',
                          subtitle: 'Age',
                        ),
                        _DetailDivider(),
                        _DetailItem(
                          label: 'Height',
                          value: metrics.formattedHeight,
                          subtitle: 'Height',
                        ),
                        _DetailDivider(),
                        _DetailItem(
                          label: 'Weight',
                          value: metrics.formattedWeight,
                          subtitle: 'Weight',
                        ),
                        _DetailDivider(),
                        _DetailItem(
                          label: 'Activity',
                          value: metrics.activityLevel,
                          subtitle: 'Level',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Color-coded automatic BMI indicator
                  _BmiCard(
                    bmi: metrics.bmi,
                    status: metrics.bmiStatus,
                    label: metrics.bmiLabel,
                    onTap: () => _showBmiGuide(context, metrics),
                  ),
                  const SizedBox(height: 16),
                  // Nutrition Goal Card
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    onTap: () => showGoalSheet(context),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.primaryWash,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.track_changes_rounded,
                            color: colors.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Goal Settings',
                                style: AppTypography.itemTitle.copyWith(
                                  color: scheme.onSurface,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _goalSubtitle(l10n, goal),
                                style: AppTypography.caption.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Help and About Card
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    onTap: () => showHelpSheet(context),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.washOf(colors.gold),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.help_outline_rounded,
                            color: colors.gold,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Help & Privacy',
                                style: AppTypography.itemTitle.copyWith(
                                  color: scheme.onSurface,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '100% offline, private, and free forever',
                                style: AppTypography.caption.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBmiGuide(BuildContext context, BodyMetrics metrics) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'BMI Categories Guide',
                style: AppTypography.titleM.copyWith(
                  fontSize: 18,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Body Mass Index (BMI) is calculated from your height and weight.',
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _BmiGuideRow(
                color: colors.danger,
                range: '< 17.0',
                label: 'Severely Underweight',
              ),
              _BmiGuideRow(
                color: colors.warning,
                range: '17.0 – 18.4',
                label: 'Borderline Underweight',
              ),
              _BmiGuideRow(
                color: colors.success,
                range: '18.5 – 24.9',
                label: 'Healthy / Normal Range',
              ),
              _BmiGuideRow(
                color: colors.warning,
                range: '25.0 – 29.9',
                label: 'Borderline Overweight',
              ),
              _BmiGuideRow(
                color: colors.danger,
                range: '≥ 30.0',
                label: 'Obese Range',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BmiGuideRow extends StatelessWidget {
  const _BmiGuideRow({
    required this.color,
    required this.range,
    required this.label,
  });

  final Color color;
  final String range;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(
              range,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.itemTitle.copyWith(
              color: scheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({
    required this.bmi,
    required this.status,
    required this.label,
    required this.onTap,
  });

  final double? bmi;
  final BmiStatus status;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    // Success if healthy, warning at the edges, danger when under or
    // over. Same token mapping as the guide rows and the live preview.
    final color = switch (status) {
      BmiStatus.unknown => scheme.onSurfaceVariant,
      BmiStatus.severelyUnderweight => colors.danger,
      BmiStatus.slightlyUnderweight => colors.warning,
      BmiStatus.normal => colors.success,
      BmiStatus.overweight => colors.warning,
      BmiStatus.obese => colors.danger,
    };

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.washOf(color),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.monitor_weight_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'BMI',
                      style: AppTypography.itemTitle.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.washOf(color),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status == BmiStatus.unknown
                            ? 'Pending'
                            : status == BmiStatus.normal
                            ? 'Healthy'
                            : status == BmiStatus.slightlyUnderweight ||
                                  status == BmiStatus.overweight
                            ? 'Edge'
                            : 'Alert',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            bmi?.toStringAsFixed(1) ?? '—',
            style: AppTypography.value20.copyWith(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _editProfile(
  BuildContext context,
  WidgetRef ref,
  BodyMetrics current,
) async {
  final nameCtrl = TextEditingController(text: current.name);
  var heightUnit = current.useFeet ? 'ft' : 'cm';
  var weightUnit = current.useLbs ? 'lb' : 'kg';
  var activity = current.activityLevel;
  DateTime? dob = current.dateOfBirth;

  double? currentHeightDisplay = current.heightCm != null
      ? (current.useFeet ? current.heightCm! / 30.48 : current.heightCm)
      : null;
  double? currentWeightDisplay = current.weightKg != null
      ? (current.useLbs ? current.weightKg! * 2.20462 : current.weightKg)
      : null;

  final heightCtrl = TextEditingController(
    text: currentHeightDisplay != null
        ? currentHeightDisplay.toStringAsFixed(1)
        : '',
  );
  final weightCtrl = TextEditingController(
    text: currentWeightDisplay != null
        ? currentWeightDisplay.toStringAsFixed(1)
        : '',
  );

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final scheme = Theme.of(context).colorScheme;
        final colors = context.appColors;

        // Calculate preview BMI
        final parsedH = double.tryParse(heightCtrl.text);
        final parsedW = double.tryParse(weightCtrl.text);
        final realHeightCm = parsedH != null
            ? (heightUnit == 'ft' ? parsedH * 30.48 : parsedH)
            : current.heightCm;
        final realWeightKg = parsedW != null
            ? (weightUnit == 'lb' ? parsedW / 2.20462 : parsedW)
            : current.weightKg;

        double? previewBmi;
        if (realHeightCm != null && realWeightKg != null && realHeightCm > 0) {
          previewBmi =
              realWeightKg / ((realHeightCm / 100) * (realHeightCm / 100));
        }

        final bmiColor = previewBmi == null
            ? scheme.onSurfaceVariant
            : previewBmi < 17.0
            ? colors.danger
            : previewBmi < 18.5
            ? colors.warning
            : previewBmi < 25.0
            ? colors.success
            : previewBmi < 30.0
            ? colors.warning
            : colors.danger;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit Personal Details',
                  style: AppTypography.titleM.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Height ($heightUnit)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'cm', label: Text('cm')),
                        ButtonSegment(value: 'ft', label: Text('ft')),
                      ],
                      selected: {heightUnit},
                      onSelectionChanged: (selection) => setState(() {
                        final next = selection.first;
                        final parsed = double.tryParse(heightCtrl.text);
                        if (parsed != null) {
                          heightCtrl.text =
                              (next == 'ft' ? parsed / 30.48 : parsed * 30.48)
                                  .toStringAsFixed(1);
                        }
                        heightUnit = next;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Weight ($weightUnit)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'kg', label: Text('kg')),
                        ButtonSegment(value: 'lb', label: Text('lb')),
                      ],
                      selected: {weightUnit},
                      onSelectionChanged: (selection) => setState(() {
                        final next = selection.first;
                        final parsed = double.tryParse(weightCtrl.text);
                        if (parsed != null) {
                          weightCtrl.text =
                              (next == 'lb'
                                      ? parsed * 2.20462
                                      : parsed / 2.20462)
                                  .toStringAsFixed(1);
                        }
                        weightUnit = next;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date of Birth picker row
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dob ?? DateTime(2000, 1, 1),
                      firstDate: DateTime(1930),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => dob = picked);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dob != null
                                ? 'Born: ${dob!.day}/${dob!.month}/${dob!.year}'
                                : 'Select Date of Birth (Optional)',
                            style: TextStyle(
                              color: dob != null
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Activity level dropdown
                DropdownButtonFormField<String>(
                  value: activity,
                  decoration: const InputDecoration(
                    labelText: 'Activity Level',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Sedentary',
                      child: Text('Sedentary (Little or no exercise)'),
                    ),
                    DropdownMenuItem(
                      value: 'Light',
                      child: Text('Light (Exercise 1–3 days/wk)'),
                    ),
                    DropdownMenuItem(
                      value: 'Active',
                      child: Text('Active (Daily exercise)'),
                    ),
                    DropdownMenuItem(
                      value: 'High',
                      child: Text('High (Intense daily training)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => activity = val);
                  },
                ),
                const SizedBox(height: 14),
                // Live BMI calculation preview badge
                if (previewBmi != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.washOf(bmiColor),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: bmiColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.health_and_safety_rounded,
                          color: bmiColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Calculated BMI: ${previewBmi.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: bmiColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final h = double.tryParse(heightCtrl.text);
                      final w = double.tryParse(weightCtrl.text);
                      await ref
                          .read(bodyMetricsProvider.notifier)
                          .update(
                            name: nameCtrl.text.trim().isNotEmpty
                                ? nameCtrl.text.trim()
                                : current.name,
                            dateOfBirth: dob,
                            heightCm: h != null
                                ? (heightUnit == 'ft' ? h * 30.48 : h)
                                : null,
                            weightKg: w != null
                                ? (weightUnit == 'lb' ? w / 2.20462 : w)
                                : null,
                            activityLevel: activity,
                            useFeet: heightUnit == 'ft',
                            useLbs: weightUnit == 'lb',
                          );
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Details',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  nameCtrl.dispose();
  heightCtrl.dispose();
  weightCtrl.dispose();
}

String _goalSubtitle(AppLocalizations l10n, GoalKind kind) {
  switch (kind) {
    case GoalKind.lose:
      return l10n.goalLoseSubtitle;
    case GoalKind.maintain:
      return l10n.goalMaintainSubtitle;
    case GoalKind.gain:
      return l10n.goalGainSubtitle;
  }
}
