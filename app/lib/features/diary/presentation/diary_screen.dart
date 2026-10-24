import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/app/log_store.dart';
import 'package:app/core/format/count_format.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/progress_ring.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/diary/application/diary_state.dart';
import 'package:app/features/diary/presentation/meal_detail_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Diary per ui_design.jpg & ui_design2.jpg:
/// - Header: "Diary/", "Calorie tracker", trailing "..."
/// - Week Strip: Sun, Mon, Tue, Wed, Thu, Fri, Sat with date numbers
/// - "Calories Remaining" card with semi-circular arc gauge
/// - Meal Cards: Breakfast, Lunch, Dinner with thumbnails, kcal, macro tags
/// - Snacks Card with macro distribution bars
final selectedDiaryOffsetProvider = StateProvider<int>((ref) => 0);

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  static const maxOffset = DayLog.diaryDays - 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selectedOffset = ref.watch(selectedDiaryOffsetProvider);
    final state = ref.watch(diaryStateProvider(selectedOffset));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x2,
            AppSpacing.screenPadding,
            104,
          ),
          children: [
            _DiaryHeader(),
            const SizedBox(height: 16),
            _WeekStrip(),
            const SizedBox(height: 16),
            _CaloriesRemainingArcCard(state: state),
            const SizedBox(height: 16),
            _MealSectionList(state: state, dayOffset: selectedOffset),
            const SizedBox(height: 14),
            _SnacksMacroCard(state: state),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
          '/search?day=$selectedOffset&meal=${mealForHour(DateTime.now().hour).name}',
        ),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

class _DiaryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diary/',
              style: AppTypography.titleL.copyWith(
                color: scheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Calorie tracker',
              style: AppTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurface),
        ),
      ],
    );
  }
}

class _WeekStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final selectedOffset = ref.watch(selectedDiaryOffsetProvider);
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      spacing: 6,
      children: [
        for (var i = 6; i >= 0; i--)
          Expanded(
            child: () {
              final date = today.subtract(Duration(days: i));
              final dayName = weekDays[date.weekday % 7];
              final isSelected = i == selectedOffset;

              return Material(
                color: isSelected ? colors.gold : scheme.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => ref.read(selectedDiaryOffsetProvider.notifier).state = i,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? colors.gold : scheme.outlineVariant,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : scheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : scheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }(),
          ),
      ],
    );
  }
}

/// Semi-circular Arc Gauge Card matching ui_design2.jpg Screen 4
class _CaloriesRemainingArcCard extends StatelessWidget {
  const _CaloriesRemainingArcCard({required this.state});

  final DiaryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final remaining = state.caloriesRemaining;
    final target = state.caloriesTarget;
    final progress = target > 0 ? (state.caloriesConsumed / target).clamp(0.0, 1.0) : 0.0;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Calories Remaining',
                style: AppTypography.titleM.copyWith(
                  color: scheme.onSurface,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: ProgressRing(
              isArc: true,
              progress: 1.0 - progress,
              size: 160,
              strokeWidth: 14,
              gradientColors: colors.calorieRingColors,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${formatCount(remaining)}+',
                    style: TextStyle(
                      fontFamily: AppTypography.family,
                      color: scheme.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Remaining',
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Meal sections: Breakfast, Lunch, Dinner
class _MealSectionList extends StatelessWidget {
  const _MealSectionList({required this.state, required this.dayOffset});

  final DiaryState state;
  final int dayOffset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byMeal = <MealKind, List<MealLogEntry>>{
      for (final e in state.mealLog) e.mealKind: [],
    };
    for (final e in state.mealLog) {
      byMeal[e.mealKind]!.add(e);
    }

    const mainMeals = [MealKind.breakfast, MealKind.lunch, MealKind.dinner];

    return Column(
      children: [
        for (final meal in mainMeals) ...[
          _MealRowCard(
            meal: meal,
            entries: byMeal[meal] ?? const [],
            dayOffset: dayOffset,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MealRowCard extends StatelessWidget {
  const _MealRowCard({
    required this.meal,
    required this.entries,
    required this.dayOffset,
  });

  final MealKind meal;
  final List<MealLogEntry> entries;
  final int dayOffset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final hasEntries = entries.isNotEmpty;
    final kcal = entries.fold<int>(0, (sum, e) => sum + e.calories);
    var protein = 0, carbs = 0, fat = 0;
    for (final e in entries) {
      protein += e.proteinGrams;
      carbs += e.carbsGrams;
      fat += e.fatGrams;
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => showMealDetailSheet(context, dayOffset: dayOffset, meal: meal),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              height: 52,
              color: colors.primaryWash,
              child: Image.asset(
                'assets/brand/meal_thali.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(Icons.restaurant, color: colors.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mealLabel(meal),
                  style: AppTypography.itemTitle.copyWith(
                    color: scheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // An empty meal shows no number at all. A placeholder
                  // count reads as food already logged, which is worse
                  // than showing nothing (R7).
                  hasEntries ? '$kcal kcal' : l10n.mealNotLoggedYet,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 5),
                if (hasEntries)
                  Row(
                    children: [
                      _TagBadge(
                        text: '${l10n.macroProtein} ${protein}g',
                        color: colors.macroProtein,
                      ),
                      const SizedBox(width: 5),
                      _TagBadge(
                        text: '${l10n.macroCarbs} ${carbs}g',
                        color: colors.macroCarbs,
                      ),
                      const SizedBox(width: 5),
                      _TagBadge(
                        text: '${l10n.macroFat} ${fat}g',
                        color: colors.macroFat,
                      ),
                    ],
                  )
                else
                  _TagBadge(
                    text: '+ ${l10n.addFood}',
                    color: colors.primary,
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 20, color: scheme.onSurfaceVariant),
            onSelected: (val) {
              if (val == 'add') {
                context.push('/search?day=$dayOffset&meal=${meal.name}');
              } else if (val == 'scan') {
                context.push('/scan?day=$dayOffset&meal=${meal.name}');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'add', child: Text(l10n.addFood)),
              PopupMenuItem(value: 'scan', child: Text(l10n.scanScreenTitle)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Snacks Card from ui_design.jpg Screen 6 with a macro breakdown bar.
///
/// Every number is computed from the snacks actually logged. It used to
/// be fixed decoration - a hard-coded "280 kcal" and a 50/30/20 bar -
/// which read as logged food on a day that had none.
class _SnacksMacroCard extends StatelessWidget {
  const _SnacksMacroCard({required this.state});

  final DiaryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    var kcal = 0, protein = 0, carbs = 0, fat = 0;
    for (final e in state.mealLog) {
      if (e.mealKind != MealKind.snacks) continue;
      kcal += e.calories;
      protein += e.proteinGrams;
      carbs += e.carbsGrams;
      fat += e.fatGrams;
    }

    // Weight the bar by energy share, not grams: 1 g of fat is ~9 kcal
    // against ~4 for protein and carbs, so a gram-based bar would
    // understate fat.
    final segments = <(int, Color)>[
      (carbs * 4, colors.macroCarbs),
      (protein * 4, colors.macroProtein),
      (fat * 9, colors.macroFat),
    ]..removeWhere((segment) => segment.$1 <= 0);
    final energy = segments.fold<int>(0, (sum, s) => sum + s.$1);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.mealSnacks,
                style: AppTypography.itemTitle.copyWith(
                  color: scheme.onSurface,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                energy == 0
                    ? l10n.mealNotLoggedYet
                    : '$kcal ${l10n.kcalUnit}',
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (energy > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    for (var i = 0; i < segments.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Expanded(
                        flex: (segments[i].$1 / energy * 1000).round(),
                        child: ColoredBox(color: segments[i].$2),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _MacroLegendDot(
                  label: '${l10n.macroCarbs} ${carbs}g',
                  color: colors.macroCarbs,
                ),
                const SizedBox(width: 14),
                _MacroLegendDot(
                  label: '${l10n.macroProtein} ${protein}g',
                  color: colors.macroProtein,
                ),
                const SizedBox(width: 14),
                _MacroLegendDot(
                  label: '${l10n.macroFat} ${fat}g',
                  color: colors.macroFat,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroLegendDot extends StatelessWidget {
  const _MacroLegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
