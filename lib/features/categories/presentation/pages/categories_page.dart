import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/category.dart';
import '../cubit/categories_list_cubit.dart';
import '../cubit/categories_list_state.dart';
import '../widgets/categories_empty_state.dart';
import '../widgets/categories_error_view.dart';
import '../widgets/category_accordion_row.dart';
import '../widgets/skeleton_row.dart';

/// The categories list (`bA51N`/`vH7RI`/`QZAKU`/`oaBzm`).
///
/// No `Page Header`/`Tab Bar`: title "Categorías" + `+` button directly, same
/// pattern as Presupuestos/Metas — Categorías is reached from elsewhere, not
/// a top-level tab.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({
    required this.onAddCategory,
    required this.onAddSubcategory,
    required this.onOpenCategory,
    super.key,
  });

  /// Creates a root category of the currently active kind.
  final ValueChanged<CategoryKind> onAddCategory;

  /// Creates a subcategory of the given root id.
  final ValueChanged<String> onAddSubcategory;

  /// Opens a category (root or sub) for editing.
  final ValueChanged<String> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoriesTitle),
        actions: [
          BlocBuilder<CategoriesListCubit, CategoriesListState>(
            builder: (context, state) => IconButton(
              onPressed: () => onAddCategory(state.kind),
              tooltip: l10n.categoriesAdd,
              icon: const Icon(LucideIcons.plus),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: BlocBuilder<CategoriesListCubit, CategoriesListState>(
                builder: (context, state) => CategoryKindToggle(
                  selected: state.kind,
                  onChanged: context.read<CategoriesListCubit>().selectKind,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<CategoriesListCubit, CategoriesListState>(
                builder: (context, state) => switch (state.status) {
                  CategoriesListStatus.loading => const CategoriesLoadingView(),
                  CategoriesListStatus.failure => CategoriesErrorView(
                      onRetry: () => context.read<CategoriesListCubit>().start(
                            kind: state.kind,
                          ),
                    ),
                  CategoriesListStatus.ready when state.nodes.isEmpty =>
                    CategoriesEmptyState(
                      kind: state.kind,
                      onAddCategory: () => onAddCategory(state.kind),
                    ),
                  CategoriesListStatus.ready => CategoriesListView(
                      state: state,
                      onAddSubcategory: onAddSubcategory,
                      onOpenCategory: onOpenCategory,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The `Segmented Control` toggle (`hFu41`), Gasto/Ingreso only — categories
/// never apply to transfers, so that 3rd segment stays hidden.
///
/// "Gasto" renders in `$text-primary`, never `$expense`: labeling it red
/// felt punitive (`categorias.md`).
class CategoryKindToggle extends StatelessWidget {
  const CategoryKindToggle({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final CategoryKind selected;
  final ValueChanged<CategoryKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: CategoryKindSegment(
              label: l10n.categoryKindExpense,
              selected: selected == CategoryKind.expense,
              onTap: () => onChanged(CategoryKind.expense),
            ),
          ),
          Expanded(
            child: CategoryKindSegment(
              label: l10n.categoryKindIncome,
              selected: selected == CategoryKind.income,
              onTap: () => onChanged(CategoryKind.income),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryKindSegment extends StatelessWidget {
  const CategoryKindSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Loading: 6 `Skeleton Row`s with varied widths, same geometry as the real
/// rows (`QZAKU`).
class CategoriesLoadingView extends StatelessWidget {
  const CategoriesLoadingView({super.key});

  static const List<double> _widths = [140, 100, 160, 120, 90, 150];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).categoriesLoading,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _widths.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            CategorySkeletonRow(nameWidth: _widths[index]),
      ),
    );
  }
}

/// The list with data: root categories in an accordion, reorderable by
/// long-press (HU-05), same criterion as Cuentas.
class CategoriesListView extends StatelessWidget {
  const CategoriesListView({
    required this.state,
    required this.onAddSubcategory,
    required this.onOpenCategory,
    super.key,
  });

  final CategoriesListState state;
  final ValueChanged<String> onAddSubcategory;
  final ValueChanged<String> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CategoriesListCubit>();

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      itemCount: state.nodes.length,
      onReorder: cubit.reorder,
      itemBuilder: (context, index) {
        final node = state.nodes[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(node.root.id),
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CategoryAccordionRow(
              node: node,
              expanded: state.isExpanded(node.root.id),
              onToggle: () => cubit.toggleExpanded(node.root.id),
              onAddSubcategory: () => onAddSubcategory(node.root.id),
              onTapSubcategory: onOpenCategory,
              onEditRoot: () => onOpenCategory(node.root.id),
            ),
          ),
        );
      },
    );
  }
}
