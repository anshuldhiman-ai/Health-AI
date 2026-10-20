import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app/log_store.dart';
import 'package:app/data/nutrition/dish_catalog.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/empty_state.dart';
import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/dish_info.dart';
import 'package:app/domain/entities/food_portion.dart';
import 'package:app/domain/entities/log_entry.dart';
import 'package:app/domain/entities/macro.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/search/presentation/dish_visuals.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

enum _DetailTab { nutrition, ingredients, portions }

/// Dish details for the manual search flow: portion selection, local
/// nutrition/ingredient data and an add-to-diary action for the chosen
/// day and meal. No separate nutrition model is introduced.
class DishDetailScreen extends ConsumerStatefulWidget {
  const DishDetailScreen({
    required this.dishId,
    required this.dayOffset,
    required this.initialMeal,
    super.key,
  });

  final String dishId;
  final int dayOffset;
  final MealKind initialMeal;

  @override
  ConsumerState<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends ConsumerState<DishDetailScreen> {
  late MealKind _meal = widget.initialMeal;
  _DetailTab _tab = _DetailTab.nutrition;
  int _servingIndex = 0;

  void _add(DishInfo dish, FoodPortion serving) {
    final l10n = AppLocalizations.of(context)!;
    final store = ref.read(dayLogProvider.notifier);
    store.add(
      LogEntry(
        mealKind: _meal,
        dish: dish.name,
        kcal: serving.midKcal,
        proteinGrams: serving.proteinGrams,
        carbsGrams: serving.carbsGrams,
        fatGrams: serving.fatGrams,
        timeLabel: TimeOfDay.now().format(context),
      ),
      dayOffset: widget.dayOffset,
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(l10n.addedToast(l10n.mealLabel(_meal))),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            messenger.hideCurrentSnackBar();
            store.removeNewest(widget.dayOffset);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(dishCatalogProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: catalog.when(
          loading: () => Column(
            children: [
              _Header(title: l10n.dishDetails),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
          error: (_, _) => Column(
            children: [
              _Header(title: l10n.dishDetails),
              Expanded(
                child: EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: l10n.catalogLoadError,
                  message: l10n.noDishesFoundHint,
                  actionLabel: l10n.activityRefresh,
                  onAction: () => ref.invalidate(dishCatalogProvider),
                ),
              ),
            ],
          ),
          data: (catalog) {
            final dish = catalog.dishes[widget.dishId];
            if (dish == null) {
              return Column(
                children: [
                  _Header(title: l10n.dishDetails),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: l10n.noDishesFound,
                      message: l10n.noDishesFoundHint,
                    ),
                  ),
                ],
              );
            }
            final portions = portionOptionsFor(dish);
            if (portions.isEmpty) {
              return Column(
                children: [
                  _Header(title: dish.name),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.info_outline_rounded,
                      title: l10n.noDishesFound,
                      message: l10n.catalogNote,
                    ),
                  ),
                ],
              );
            }
            final index = _servingIndex.clamp(0, portions.length - 1);
            final serving = portions[index];
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.x2,
                          AppSpacing.screenPadding,
                          0,
                        ),
                        child: _Header(
                          title: dish.name,
                          subtitle: widget.dayOffset == 0
                              ? null
                              : l10n.dayOffsetLabel(widget.dayOffset),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: _DishHero(dish: dish, serving: serving),
                      ),
                      const SizedBox(height: 16),
                      _ServingStrip(
                        portions: portions,
                        selected: index,
                        onSelected: (value) =>
                            setState(() => _servingIndex = value),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: _TabStrip(
                          selected: _tab,
                          onSelected: (tab) => setState(() => _tab = tab),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: switch (_tab) {
                          _DetailTab.nutrition => _NutritionTab(
                            dish: dish,
                            serving: serving,
                          ),
                          _DetailTab.ingredients => _IngredientsTab(dish: dish),
                          _DetailTab.portions => _PortionsTab(
                            portions: portions,
                            selected: index,
                            onSelected: (value) =>
                                setState(() => _servingIndex = value),
                          ),
                        },
                      ),
                    ],
                  ),
                ),
                _AddBar(
                  meal: _meal,
                  serving: serving,
                  onMeal: (meal) => setState(() => _meal = meal),
                  onAdd: () => _add(dish, serving),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleL.copyWith(color: scheme.onSurface),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DishHero extends StatelessWidget {
  const _DishHero({required this.dish, required this.serving});

  final DishInfo dish;
  final FoodPortion serving;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.primaryWash,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              familyIcon(dish.family),
              size: 34,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dishFamilyLabel(dish.family),
                  style: AppTypography.caption.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dish.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleM.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 5),
                Text(
                  '${serving.lowKcal}–${serving.highKcal} ${l10n.kcalUnit} · '
                  '${l10n.perServing}',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServingStrip extends StatelessWidget {
  const _ServingStrip({
    required this.portions,
    required this.selected,
    required this.onSelected,
  });

  final List<FoodPortion> portions;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        itemCount: portions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final portion = portions[index];
          return ChoiceChip(
            label: Text('${portion.label} · ${portion.grams} ${l10n.gramUnit}'),
            selected: selected == index,
            onSelected: (_) => onSelected(index),
          );
        },
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.selected, required this.onSelected});

  final _DetailTab selected;
  final ValueChanged<_DetailTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tabs = [
      (_DetailTab.nutrition, l10n.nutritionTab),
      (_DetailTab.ingredients, l10n.ingredientsTab),
      (_DetailTab.portions, l10n.portionsTab),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appColors.canvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final (tab, label) in tabs)
            Expanded(
              child: Material(
                color: selected == tab ? scheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  onTap: () => onSelected(tab),
                  borderRadius: BorderRadius.circular(11),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: selected == tab
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        fontWeight: selected == tab
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NutritionTab extends StatelessWidget {
  const _NutritionTab({required this.dish, required this.serving});

  final DishInfo dish;
  final FoodPortion serving;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final per100 = dish.per100g;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            children: [
              _NutritionRow(
                label: l10n.caloriesLabel,
                value:
                    '${serving.lowKcal}–${serving.highKcal} ${l10n.kcalUnit}',
              ),
              _NutritionRow(
                label: l10n.macroLabel(MacroKind.protein),
                value: '${serving.proteinGrams} ${l10n.gramUnit}',
              ),
              _NutritionRow(
                label: l10n.macroLabel(MacroKind.carbs),
                value: '${serving.carbsGrams} ${l10n.gramUnit}',
              ),
              _NutritionRow(
                label: l10n.macroLabel(MacroKind.fat),
                value: '${serving.fatGrams} ${l10n.gramUnit}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.per100g,
                style: AppTypography.itemS.copyWith(
                  color: scheme.onSurface,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 8),
              _NutritionRow(
                label: l10n.caloriesLabel,
                value: '${per100.kcal.round()} ${l10n.kcalUnit}',
              ),
              _NutritionRow(
                label: l10n.macroLabel(MacroKind.protein),
                value: '${per100.protein.toStringAsFixed(1)} ${l10n.gramUnit}',
              ),
              _NutritionRow(
                label: l10n.macroLabel(MacroKind.carbs),
                value: '${per100.carbs.toStringAsFixed(1)} ${l10n.gramUnit}',
              ),
              _NutritionRow(
                label: l10n.macroLabel(MacroKind.fat),
                value: '${per100.fat.toStringAsFixed(1)} ${l10n.gramUnit}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Note(text: l10n.catalogNote),
      ],
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyM.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.itemS.copyWith(
              color: scheme.onSurface,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsTab extends StatelessWidget {
  const _IngredientsTab({required this.dish});

  final DishInfo dish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ingredient in dish.ingredients)
                Chip(
                  label: Text(ingredient),
                  side: BorderSide.none,
                  backgroundColor: context.appColors.canvas,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Note(text: l10n.ingredientsNote),
      ],
    );
  }
}

class _PortionsTab extends StatelessWidget {
  const _PortionsTab({
    required this.portions,
    required this.selected,
    required this.onSelected,
  });

  final List<FoodPortion> portions;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupHeader(title: l10n.selectServing),
        const SizedBox(height: 10),
        for (var i = 0; i < portions.length; i++) ...[
          AppCard(
            onTap: () => onSelected(i),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  selected == i
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected == i
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        portions[i].label,
                        style: AppTypography.itemS.copyWith(
                          color: scheme.onSurface,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        '${portions[i].grams} ${l10n.gramUnit}',
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${portions[i].lowKcal}–${portions[i].highKcal} '
                  '${l10n.kcalUnit}',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.accentWash,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 9,
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: colors.accent),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBar extends StatelessWidget {
  const _AddBar({
    required this.meal,
    required this.serving,
    required this.onMeal,
    required this.onAdd,
  });

  final MealKind meal;
  final FoodPortion serving;
  final ValueChanged<MealKind> onMeal;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 12,
      shadowColor: scheme.shadow.withValues(alpha: 0.18),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    l10n.selectMeal,
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      children: [
                        for (final kind in MealKind.values)
                          ChoiceChip(
                            label: Text(l10n.mealLabel(kind)),
                            selected: meal == kind,
                            onSelected: (_) => onMeal(kind),
                            visualDensity: VisualDensity.compact,
                            labelStyle: const TextStyle(fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  '${l10n.addToDiary} · ${serving.midKcal} ${l10n.kcalUnit}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
