import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/data/preferences/body_metrics_controller.dart';
import 'package:app/domain/entities/nutrition_targets.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:app/features/profile/presentation/goal_sheet.dart';
import 'package:app/features/profile/presentation/help_sheet.dart';
import 'package:app/features/profile/presentation/settings_sheet.dart';
import 'package:app/l10n/app_localizations.dart';

/// Local account and body measurements.
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
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding, AppSpacing.x2,
            AppSpacing.screenPadding, 96,
          ),
          children: [
            Row(children: [
              Text('Account', style: AppTypography.titleL.copyWith(color: scheme.onSurface)),
              const Spacer(),
              IconButton(onPressed: () => showSettingsSheet(context), icon: const Icon(Icons.settings_outlined)),
            ]),
            const SizedBox(height: 18),
            Center(
              child: CircleAvatar(
                radius: 43,
                backgroundColor: colors.primaryWash,
                child: Icon(Icons.person_rounded, size: 42, color: colors.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text('Your profile', textAlign: TextAlign.center,
              style: AppTypography.titleL.copyWith(color: scheme.onSurface, fontSize: 21)),
            const SizedBox(height: 4),
            Text('Your health details stay on this device.', textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: Text('Body measurements', style: AppTypography.titleM.copyWith(color: scheme.onSurface))),
              TextButton.icon(onPressed: () => _editMeasurements(context, ref, metrics),
                icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit')),
            ]),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(children: [
                _DetailItem(label: 'Height', value: metrics.heightCm == null ? 'Add height' : '${metrics.heightCm!.toStringAsFixed(0)} cm', subtitle: '↕'),
                _DetailDivider(),
                _DetailItem(label: 'Weight', value: metrics.weightKg == null ? 'Add weight' : '${metrics.weightKg!.toStringAsFixed(1)} kg', subtitle: '⚖'),
              ]),
            ),
            const SizedBox(height: 12),
            _BmiCard(bmi: metrics.bmi),
            const SizedBox(height: 22),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              onTap: () => showGoalSheet(context),
              child: Row(children: [
                Icon(Icons.track_changes_rounded, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Nutrition goal', style: AppTypography.itemTitle.copyWith(color: scheme.onSurface)),
                  Text(_goalSubtitle(l10n, goal), style: AppTypography.caption.copyWith(color: scheme.onSurfaceVariant)),
                ])),
                Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
              ]),
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              onTap: () => showHelpSheet(context),
              child: Row(children: [
                Icon(Icons.help_outline_rounded, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Help and about', style: AppTypography.itemTitle.copyWith(color: scheme.onSurface))),
                Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
              ]),
            ),
          ],
        ),
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
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTypography.itemTitle.copyWith(
              color: scheme.onSurface,
              fontSize: 13.5,
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
      height: 28,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.bmi});

  final double? bmi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = bmi;
    final color = value == null
        ? scheme.onSurfaceVariant
        : value < 18.5 || value >= 30
            ? scheme.error
            : value < 20 || value >= 25
                ? const Color(0xFFE3A323)
                : const Color(0xFF25805B);
    final label = value == null
        ? 'Add height and weight to calculate BMI'
        : value < 18.5
            ? 'Below the healthy range'
            : value < 20
                ? 'Near the lower edge'
                : value < 25
                    ? 'Healthy range'
                : value < 30
                    ? 'Near or above the upper edge'
                    : 'High BMI range';
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(Icons.monitor_weight_outlined, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BMI', style: AppTypography.itemTitle.copyWith(color: scheme.onSurface)),
          Text(label, style: AppTypography.caption.copyWith(color: color)),
        ])),
        Text(value?.toStringAsFixed(1) ?? '—',
          style: AppTypography.value20.copyWith(color: color, fontSize: 22)),
      ]),
    );
  }
}

Future<void> _editMeasurements(
  BuildContext context,
  WidgetRef ref,
  BodyMetrics current,
) async {
  var heightUnit = 'cm';
  var weightUnit = 'kg';
  final height = TextEditingController(
    text: current.heightCm == null ? '' : current.heightCm!.toStringAsFixed(0),
  );
  final weight = TextEditingController(
    text: current.weightKg == null ? '' : current.weightKg!.toStringAsFixed(1),
  );
  final saved = await showModalBottomSheet<BodyMetrics>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(builder: (context, setState) {
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Body measurements', style: AppTypography.titleM.copyWith(color: scheme.onSurface)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: height, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Height ($heightUnit)'))),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'cm', label: Text('cm')), ButtonSegment(value: 'ft', label: Text('ft'))],
              selected: {heightUnit},
              onSelectionChanged: (selection) => setState(() {
                final next = selection.first;
                final parsed = double.tryParse(height.text);
                if (parsed != null) height.text = (next == 'ft' ? parsed / 30.48 : parsed * 30.48).toStringAsFixed(1);
                heightUnit = next;
              }),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Weight ($weightUnit)'))),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'kg', label: Text('kg')), ButtonSegment(value: 'lb', label: Text('lb'))],
              selected: {weightUnit},
              onSelectionChanged: (selection) => setState(() {
                final next = selection.first;
                final parsed = double.tryParse(weight.text);
                if (parsed != null) weight.text = (next == 'lb' ? parsed * 2.20462 : parsed / 2.20462).toStringAsFixed(1);
                weightUnit = next;
              }),
            ),
          ]),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              final h = double.tryParse(height.text);
              final w = double.tryParse(weight.text);
              if (h == null || w == null || h <= 0 || w <= 0) return;
              Navigator.of(sheetContext).pop(BodyMetrics(
                heightCm: heightUnit == 'ft' ? h * 30.48 : h,
                weightKg: weightUnit == 'lb' ? w / 2.20462 : w,
              ));
            },
            child: const Text('Save measurements'),
          ),
        ]),
      );
    }),
  );
  height.dispose();
  weight.dispose();
  if (saved != null) {
    ref.read(bodyMetricsProvider.notifier).update(
      heightCm: saved.heightCm,
      weightKg: saved.weightKg,
    );
  }
}

String _goalSubtitle(AppLocalizations l10n, GoalKind kind) => switch (kind) {
  GoalKind.lose => l10n.goalLoseSubtitle,
  GoalKind.maintain => l10n.goalMaintainSubtitle,
  GoalKind.gain => l10n.goalGainSubtitle,
};
