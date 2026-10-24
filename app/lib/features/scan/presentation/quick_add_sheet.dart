import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/ui/family_icon.dart';
import 'package:app/data/nutrition/dish_catalog.dart';
import 'package:app/data/nutrition/dish_query.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/dish_info.dart';
import 'package:app/l10n/app_localizations.dart';

/// Predefined popular packaged foods for quick add (Maggi, Biscuits, Oats, Bread, etc.)
class PackagedFoodItem {
  const PackagedFoodItem({
    required this.name,
    required this.brand,
    required this.kcal,
    required this.servingLabel,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String name;
  final String brand;
  final int kcal;
  final String servingLabel;
  final int protein;
  final int carbs;
  final int fat;
}

const packagedFoods = [
  PackagedFoodItem(
    name: 'Maggi 2-Minute Masala Noodles',
    brand: 'Nestlé',
    kcal: 312,
    servingLabel: '1 pack (70g)',
    protein: 8,
    carbs: 44,
    fat: 12,
  ),
  PackagedFoodItem(
    name: 'Parle-G Glucose Biscuits',
    brand: 'Parle',
    kcal: 145,
    servingLabel: '4 biscuits (32g)',
    protein: 2,
    carbs: 25,
    fat: 4,
  ),
  PackagedFoodItem(
    name: 'Quaker Rolled Oats',
    brand: 'Quaker',
    kcal: 190,
    servingLabel: '1 bowl cooked (50g)',
    protein: 6,
    carbs: 32,
    fat: 4,
  ),
  PackagedFoodItem(
    name: 'Amul Butter',
    brand: 'Amul',
    kcal: 108,
    servingLabel: '1 tbsp (15g)',
    protein: 0,
    carbs: 0,
    fat: 12,
  ),
  PackagedFoodItem(
    name: 'Britannia Whole Wheat Bread',
    brand: 'Britannia',
    kcal: 140,
    servingLabel: '2 slices (50g)',
    protein: 5,
    carbs: 26,
    fat: 2,
  ),
  PackagedFoodItem(
    name: 'Kurkure Masala Munch',
    brand: 'PepsiCo',
    kcal: 170,
    servingLabel: '1 small pack (32g)',
    protein: 2,
    carbs: 18,
    fat: 10,
  ),
];

const List<String> quickPickIds = [
  'samosa',
  'papad',
  'banana chips',
  'khakhra',
  'chivda',
  'popcorn',
  'toast',
  'lassi',
  'chaas',
  'chai',
];

/// Quick-add packaged foods or cooked dishes by hand without requiring camera scanning.
class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key, this.onManualAdd, this.initialFoodName});

  final Future<void> Function(String name, int kcal)? onManualAdd;
  final String? initialFoodName;

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialFoodName != null) {
      _controller.text = widget.initialFoodName!;
      _query = widget.initialFoodName!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final catalog = ref.watch(dishCatalogProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.x3),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.x3,
                AppSpacing.screenPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Add & Packaged Foods',
                    style: AppTypography.titleM.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    'Search packaged snacks (e.g. Maggi, Oats, Biscuits) or cooked dishes.',
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.x3,
                AppSpacing.screenPadding,
                0,
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search food or brand (e.g. Maggi, Bread)...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
              ),
            ),
            // Packaged Food Quick Section when search is empty or matches
            _buildPackagedFoodsSection(context, scheme),
            catalog.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.x8),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.x6),
                child: Text(
                  l10n.quickAddNoCatalog,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyM.copyWith(color: scheme.error),
                ),
              ),
              data: (data) => _Results(
                catalog: data,
                query: _query,
                onPick: (dish) => Navigator.of(context).pop(dish.id),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.x3,
              ),
              child: OutlinedButton.icon(
                onPressed: _openCustomFoodDialog,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Add Custom Item & Calories'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackagedFoodsSection(BuildContext context, ColorScheme scheme) {
    final lower = _query.trim().toLowerCase();
    final filteredPackaged = packagedFoods.where((item) {
      if (lower.isEmpty) return true;
      return item.name.toLowerCase().contains(lower) ||
          item.brand.toLowerCase().contains(lower);
    }).toList();

    if (filteredPackaged.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 12, AppSpacing.screenPadding, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                'Packaged Foods',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filteredPackaged.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final item = filteredPackaged[idx];
                return InkWell(
                  onTap: () async {
                    await widget.onManualAdd?.call(item.name, item.kcal);
                    if (mounted) Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 155,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        Text(
                          item.servingLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.kcal} kcal',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const Icon(Icons.add_circle, size: 16, color: Color(0xFF10B981)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomFoodDialog() async {
    final name = TextEditingController(text: _query);
    final kcal = TextEditingController();
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add custom food'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Food or dish name',
                hintText: 'e.g. Maggi Noodles, Oat biscuit',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kcal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories (kcal)',
                hintText: 'e.g. 250',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final calories = int.tryParse(kcal.text.trim());
              if (name.text.trim().isEmpty || calories == null || calories <= 0) return;
              Navigator.pop(dialogContext, (name.text.trim(), calories));
            },
            child: const Text('Add to meal'),
          ),
        ],
      ),
    );
    name.dispose();
    kcal.dispose();
    if (result == null || !mounted) return;
    await widget.onManualAdd?.call(result.$1, result.$2);
    if (mounted) Navigator.of(context).pop();
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.catalog,
    required this.query,
    required this.onPick,
  });

  final DishCatalog catalog;
  final String query;
  final ValueChanged<DishInfo> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final searchResults = filterDishes(catalog, query: query);
    final quickPicks = [
      for (final id in quickPickIds)
        if (catalog.dishes[id] != null) catalog.dishes[id]!,
    ];
    searchResults.sort((a, b) => a.name.compareTo(b.name));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (query.trim().isEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              10,
              AppSpacing.screenPadding,
              AppSpacing.x2,
            ),
            child: Text(
              l10n.quickAddPicks,
              style: AppTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                for (final dish in quickPicks)
                  ActionChip(
                    label: Text(dish.name),
                    onPressed: () => onPick(dish),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
        ] else if (searchResults.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Text(
              l10n.quickAddNoMatch,
              textAlign: TextAlign.center,
              style: AppTypography.bodyM.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          const SizedBox(height: AppSpacing.x2),
        if (searchResults.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.35,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x2,
                0,
                AppSpacing.x2,
                AppSpacing.x4,
              ),
              itemCount: searchResults.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: scheme.outlineVariant,
              ),
              itemBuilder: (_, index) {
                final dish = searchResults[index];
                return ListTile(
                  leading: _DishGlyph(family: dish.family),
                  title: Text(
                    dish.name,
                    style: AppTypography.itemS.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    dish.hasNutritionData
                        ? '${dish.per100g.kcal.round()} kcal / 100 g'
                        : l10n.quickAddNoNutrition,
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => onPick(dish),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DishGlyph extends StatelessWidget {
  const _DishGlyph({required this.family});

  final String family;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.primaryWash,
        shape: BoxShape.circle,
      ),
      child: Icon(familyIcon(family), color: scheme.primary, size: 21),
    );
  }
}
