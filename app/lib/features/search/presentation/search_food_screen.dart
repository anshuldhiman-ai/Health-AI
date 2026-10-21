import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/data/nutrition/dish_catalog.dart';
import 'package:app/design_system/components/app_card.dart';
import 'package:app/design_system/components/empty_state.dart';
import 'package:app/design_system/components/group_header.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/dish_info.dart';
import 'package:app/domain/entities/food_portion.dart';
import 'package:app/domain/entities/meal.dart';
import 'package:app/features/search/application/food_search.dart';
import 'package:app/features/search/presentation/dish_visuals.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/extensions.dart';

/// Manual food discovery over the same bundled 80-dish catalog used by
/// the camera. This is the path for dishes (kulfi, sweets, etc.) that
/// users cannot or do not want to scan.
class SearchFoodScreen extends ConsumerStatefulWidget {
  const SearchFoodScreen({
    required this.dayOffset,
    required this.initialMeal,
    super.key,
  });

  final int dayOffset;
  final MealKind initialMeal;

  @override
  ConsumerState<SearchFoodScreen> createState() => _SearchFoodScreenState();
}

class _SearchFoodScreenState extends ConsumerState<SearchFoodScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String? _family;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDish(DishInfo dish) async {
    final id = Uri.encodeComponent(dish.id);
    final added = await context.push<bool>(
      '/dish/$id?day=${widget.dayOffset}&meal=${widget.initialMeal.name}',
    );
    if (added == true && mounted) {
      Navigator.of(context).maybePop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(dishCatalogProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.x2,
                AppSpacing.screenPadding,
                0,
              ),
              child: _Header(
                title: l10n.searchFoodTitle,
                subtitle: widget.dayOffset == 0
                    ? null
                    : l10n.dayOffsetLabel(widget.dayOffset),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                16,
                AppSpacing.screenPadding,
                0,
              ),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.searchFoodHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(context)
                              .clearButtonTooltip,
                        ),
                  filled: true,
                  fillColor: scheme.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            catalog.maybeWhen(
              data: (data) => _CategoryStrip(
                families: catalogFamilies(data),
                selected: _family,
                onSelected: (family) => setState(() => _family = family),
              ),
              orElse: () => const SizedBox(height: 62),
            ),
            Expanded(
              child: catalog.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: l10n.catalogLoadError,
                    message: l10n.noDishesFoundHint,
                    actionLabel: l10n.activityRefresh,
                    onAction: () => ref.invalidate(dishCatalogProvider),
                  ),
                ),
                data: (data) {
                  final filtered = filterDishes(
                    data,
                    query: _query,
                    family: _family,
                  );
                  final showPopular = _query.trim().isEmpty && _family == null;
                  final popular = popularDishes(data);
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          12,
                          AppSpacing.screenPadding,
                          8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showPopular && popular.isNotEmpty) ...[
                                GroupHeader(title: l10n.popularDishes),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final dish in popular)
                                      ActionChip(
                                        label: Text(dish.name),
                                        onPressed: () {
                                          _controller.text = dish.name;
                                          setState(() {
                                            _query = dish.name;
                                            _family = null;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              GroupHeader(
                                title: l10n.allDishes,
                                trailing: Text(
                                  l10n.dishesCount(filtered.length),
                                  style: AppTypography.caption.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (filtered.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: EmptyState(
                                    icon: Icons.search_off_rounded,
                                    title: l10n.noDishesFound,
                                    message: l10n.noDishesFoundHint,
                                    actionLabel: l10n.categoryAll,
                                    onAction: () {
                                      _controller.clear();
                                      setState(() {
                                        _query = '';
                                        _family = null;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (filtered.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            0,
                            AppSpacing.screenPadding,
                            24,
                          ),
                          sliver: SliverList.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final dish = filtered[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _DishRow(
                                  dish: dish,
                                  onTap: () => _openDish(dish),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
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

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.families,
    required this.selected,
    required this.onSelected,
  });

  final List<String> families;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 62,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: 12,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(l10n.categoryAll),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final family in families)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(l10n.dishFamilyLabel(family)),
                selected: selected == family,
                onSelected: (_) => onSelected(family),
              ),
            ),
        ],
      ),
    );
  }
}

class _DishRow extends StatelessWidget {
  const _DishRow({required this.dish, required this.onTap});

  final DishInfo dish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final portions = portionOptionsFor(dish);
    final first = portions.isEmpty ? null : portions.first;
    final kcal = first == null
        ? ''
        : '${first.lowKcal}–${first.highKcal} ${l10n.kcalUnit}';
    final detail = [
      l10n.dishFamilyLabel(dish.family),
      if (kcal.isNotEmpty) kcal,
    ].join(' · ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryWash,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              familyIcon(dish.family),
              color: scheme.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dish.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.itemS.copyWith(
                    color: scheme.onSurface,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            size: 21,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
