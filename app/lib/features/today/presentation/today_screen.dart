import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/design_system/components/empty_state.dart';
import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/components/meter_bar.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/components/stat_tile.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/today/application/today_state.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Dashboard per ref_ui.png: greeting, date + bell, calories ring
/// with macro meters, quiet stats tiles, today's meals list.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayStateProvider);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? l10n.greetingMorning : l10n.greetingAfternoon;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x2,
            AppSpacing.screenPadding,
            AppSpacing.x6,
          ),
          children: [
            _Header(greeting: greeting),
            const SizedBox(height: AppSpacing.x2),
            Text(
              l10n.todayTagline,
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            _CaloriesRingCard(state: state),
            const SizedBox(height: AppSpacing.x4),
            QuietStatRow(
              key: const ValueKey('today-quiet-stats'),
              state: state,
            ),
            const SizedBox(height: AppSpacing.x6),
            GroupHeader(title: l10n.todaysMeals),
            const SizedBox(height: AppSpacing.x3),
            if (state.isEmpty)
              EmptyState(
                key: const ValueKey('log-first-meal'),
                icon: Icons.no_meals_outlined,
                title: l10n.logFirstMealCta,
                message: l10n.emptyDayHint,
                actionLabel: l10n.addFood,
                onAction: () => context.push('/scan?meal=lunch'),
              )
            else
              ...state.meals.map(
                (entry) => _MealCard(entry: entry),
              ),
            const _AddFoodCard(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // TODO(l10n): locale-aware date pattern (intl locale data setup).
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateLabel = 'Today, ${now.day} ${months[now.month - 1]}';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outline),
          ),
          child: Icon(
            Icons.calendar_month_outlined,
            size: 20,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(dateLabel, style: text.labelLarge),
        const Icon(Icons.keyboard_arrow_down, size: 20),
        const Spacer(),
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outline),
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 20,
                color: scheme.primary,
              ),
            ),
            Positioned(
              top: 8,
              right: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.tertiary,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CaloriesRingCard extends StatelessWidget {
  const _CaloriesRingCard({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card.x),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: state.ringProgress,
            semanticLabel:
                '${l10n.remainingKcal}: '
                '${state.caloriesRemaining} ${l10n.kcalUnit}',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.remainingKcal,
                  style: text.labelMedium?.copyWith(color: scheme.primary),
                ),
                Text(
                  '${state.caloriesRemaining}',
                  style: text.headlineMedium,
                ),
                Text(l10n.kcalUnit, style: text.labelMedium),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x4),
          Expanded(
            child: Column(
              spacing: AppSpacing.x3,
              children: [
                for (final macro in state.macros)
                  MeterBar(
                    label: l10n.macroLabel(macro.kind),
                    value: macro.value,
                    target: macro.target,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuietStatRow extends StatelessWidget {
  const QuietStatRow({required this.state, super.key});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      spacing: AppSpacing.x3,
      children: [
        for (final stat in state.stats)
          StatTile(
            icon: stat.icon,
            value: stat.value,
            caption: statCaption(l10n, stat.kind),
            expanded: true,
          ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.entry});

  final MealEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card.x),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              entry.mealKind == MealKind.breakfast
                  ? Icons.free_breakfast_outlined
                  : Icons.restaurant_outlined,
              color: scheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  l10n.mealLabel(entry.mealKind),
                  style: text.titleMedium,
                ),
                Text(
                  entry.logged
                      ? (entry.timeLabel ?? '')
                      : l10n.mealNotLoggedYet,
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (entry.logged)
            Text(
              '${entry.calories} ${l10n.kcalUnit}',
              style: text.labelLarge,
            )
          else
            FilledButton.tonal(
              onPressed: () =>
                  context.push('/scan?meal=${entry.mealKind.name}'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(l10n.addFood),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}

/// Persistent quick-add entry feeding the scan flow (the reference
/// shows the same affordance under the meal list).
class _AddFoodCard extends StatelessWidget {
  const _AddFoodCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/scan?meal=lunch'),
        borderRadius: BorderRadius.circular(AppRadii.card.x),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.card.x),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpacing.x2,
            children: [
              Icon(Icons.add, color: scheme.primary, size: 20),
              Text(
                l10n.addFood,
                style: text.labelLarge?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- local label mapping (feature-owned; only these three captions) ---

String statCaption(AppLocalizations l10n, QuietStatKind kind) {
  switch (kind) {
    case QuietStatKind.steps:
      return l10n.stepsTile;
    case QuietStatKind.water:
      return l10n.waterTile;
    case QuietStatKind.sleep:
      return l10n.sleepTile;
  }
}
