import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/preferences/water_controller.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/hydration.dart';
import 'package:app/l10n/app_localizations.dart';

/// Hydration detail opened from the dashboard's water tile. Intake and
/// the seven-day strip are stored locally; no cloud or account.
class WaterScreen extends ConsumerWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final water = ref.watch(waterTodayProvider);
    final notifier = ref.read(waterProvider.notifier);
    final glassesLabel = l10n.glassesCount(
      '${water.glasses}',
      '${HydrationState.goalGlasses}',
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x2,
            AppSpacing.screenPadding,
            AppSpacing.x8,
          ),
          children: [
            _Header(title: l10n.waterTitle),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                children: [
                  Text(
                    l10n.waterIntake,
                    style: AppTypography.itemS.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ProgressRing(
                    progress: water.progress,
                    size: 176,
                    strokeWidth: 14,
                    barColor: context.appColors.water,
                    semanticLabel:
                        '${water.liters.toStringAsFixed(1)} L, $glassesLabel',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${water.liters.toStringAsFixed(1)} L',
                          style: AppTypography.value20.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.glassesCount(
                            '${water.glasses}',
                            '${HydrationState.goalGlasses}',
                          ),
                          style: AppTypography.caption.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.waterGoal(water.goalLiters.toStringAsFixed(1)),
                    style: AppTypography.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _GlassGrid(glasses: water.glasses),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: notifier.addGlass,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(l10n.addGlass),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: water.glasses > 0 ? notifier.removeGlass : null,
              child: Text(l10n.removeGlass),
            ),
            const SizedBox(height: 18),
            GroupHeader(title: l10n.last7Days),
            const SizedBox(height: 12),
            _WeekCard(days: water.recentDays(DateTime.now())),
            const SizedBox(height: 18),
            _NoteCard(text: l10n.waterNote),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleL.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassGrid extends StatelessWidget {
  const _GlassGrid({required this.glasses});

  final int glasses;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 12,
        children: [
          for (var i = 0; i < HydrationState.goalGlasses; i++)
            Container(
              width: 38,
              height: 44,
              decoration: BoxDecoration(
                color: i < glasses
                    ? colors.accentWash
                    : context.appColors.canvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: i < glasses ? colors.accent : scheme.outlineVariant,
                ),
              ),
              child: Icon(
                i < glasses
                    ? Icons.local_drink_rounded
                    : Icons.local_drink_outlined,
                size: 21,
                color: i < glasses ? colors.accent : scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.days});

  final List<HydrationDay> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final max = days.fold<int>(1, (m, d) => d.glasses > m ? d.glasses : m);
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: SizedBox(
        height: 128,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      days[i].glasses == 0 ? '' : '${days[i].glasses}',
                      style: AppTypography.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FractionallySizedBox(
                      heightFactor: days[i].glasses / max,
                      child: Container(
                        height: 76,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: i == days.length - 1
                              ? colors.water
                              : colors.water.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      weekdays[days[i].date.weekday % 7],
                      style: AppTypography.caption.copyWith(
                        color: i == days.length - 1
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        fontWeight: i == days.length - 1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 10.5,
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
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentWash,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: colors.accent),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
