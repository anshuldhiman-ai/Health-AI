import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/format/count_format.dart';
import 'package:app/design_system/components/app_sheet.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/nutrition_targets.dart';
import 'package:app/data/preferences/goal_kind_controller.dart';
import 'package:app/l10n/app_localizations.dart';

/// Goal card entry point. Choosing a plan updates the calorie ring,
/// macro meters, diary and insights immediately.
Future<void> showGoalSheet(BuildContext context) {
  return showAppSheet<void>(context, child: const GoalSheet());
}

class GoalSheet extends ConsumerWidget {
  const GoalSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(goalKindProvider);
    final scheme = Theme.of(context).colorScheme;

    return AppSheet(
      icon: Icons.flag_rounded,
      title: l10n.myGoals,
      subtitle: l10n.chooseGoal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final kind in GoalKind.values) ...[
            _GoalOption(
              kind: kind,
              selected: kind == selected,
              onTap: () {
                ref.read(goalKindProvider.notifier).select(kind);
              },
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: scheme.primary,
            ),
            child: Text(l10n.doneLabel),
          ),
        ],
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final GoalKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final targets = targetsForGoal(kind);
    final (icon, label, hint) = switch (kind) {
      GoalKind.lose => (
        Icons.trending_down_rounded,
        l10n.goalLose,
        l10n.goalLoseHint,
      ),
      GoalKind.maintain => (
        Icons.trending_flat_rounded,
        l10n.goalMaintain,
        l10n.goalMaintainHint,
      ),
      GoalKind.gain => (
        Icons.trending_up_rounded,
        l10n.goalGain,
        l10n.goalGainHint,
      ),
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outlineVariant,
        width: selected ? 1.5 : 1,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? colors.primaryWash : scheme.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : colors.primaryWash,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: selected ? scheme.onPrimary : scheme.primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.itemS.copyWith(
                          color: scheme.onSurface,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${formatCount(targets.kcal)} ${l10n.kcalUnit}  ·  '
                        '${targets.protein}g ${l10n.macroProtein}  ·  '
                        '${targets.carbs}g ${l10n.macroCarbs}  ·  '
                        '${targets.fat}g ${l10n.macroFat}',
                        maxLines: 2,
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 20,
                  color: selected ? scheme.primary : scheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
