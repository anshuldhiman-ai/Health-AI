import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/ui/family_icon.dart';
import 'package:app/data/nutrition/dish_catalog.dart';
import 'package:app/data/nutrition/dish_query.dart';
import 'package:app/design_system/theme/app_theme.dart';
import 'package:app/design_system/tokens/tokens.dart';
import 'package:app/domain/entities/dish_info.dart';
import 'package:app/l10n/app_localizations.dart';

/// Quick picks: the catalog rows a packaged-food shortcut would point
/// at, where one exists. These are real catalog ids with real nutrition
/// rows, not a second data source.
///
/// Note what is NOT here: Maggi, biscuits, oats, branded snacks. The
/// bundled catalog is the 239-class Khana taxonomy of cooked dishes and
/// holds no branded packaged food at all, so there is no honest row to
/// offer for them. Adding one would mean inventing per-100 g macros
/// (R7). Branded coverage needs a real source - an Open Food Facts
/// India subset or an INDB packaged-food table - built into the asset
/// first. See docs/adr/ for the data-sourcing decision.
///
/// Public so a test can assert every id still resolves in the shipped
/// catalog: a typo here would silently shrink the list rather than fail
/// a build.
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

/// Quick-add a food by hand, without a photo.
///
/// This is the camera's other exit: when the model says "not a food
/// item", or the user knows the dish and does not want to scan, this
/// sheet searches the same offline catalog the search screen uses. It
/// pops the chosen dish id so the caller decides where to navigate; the
/// sheet itself never routes.
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
                    l10n.quickAddTitle,
                    style: AppTypography.titleM.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    l10n.quickAddSubtitle,
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
                  hintText: l10n.quickAddSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).deleteButtonTooltip,
                        ),
                ),
              ),
            ),
            Flexible(
              child: catalog.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.x6),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.x5),
                  child: Text(
                    l10n.quickAddUnavailable,
                    style: AppTypography.bodyM.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                data: (loaded) => _Results(
                  catalog: loaded,
                  query: _query,
                  onPick: (dish) => Navigator.of(context).pop(dish.id),
                ),
              ),
            ),
            if (widget.onManualAdd != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: OutlinedButton.icon(
                  onPressed: _addFoodManually,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Can’t find it? Add food manually'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFoodManually() async {
    final name = TextEditingController(text: widget.initialFoodName ?? '');
    final kcal = TextEditingController();
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add food'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Food name')),
          TextField(controller: kcal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories for this serving')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
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
    // The catalog is name-sorted upstream, but be explicit so the list
    // order never depends on map iteration.
    searchResults.sort((a, b) => a.name.compareTo(b.name));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (query.trim().isEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.x4,
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
          const SizedBox(height: AppSpacing.x4),
        ] else if (searchResults.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.x6),
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
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
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

/// Family icon on a wash circle. Decorative only: the dish name sits
/// right beside it as text, so the icon carries no information on its
/// own (R14).
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
