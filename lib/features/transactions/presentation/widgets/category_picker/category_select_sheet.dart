import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../../../../core/widgets/sheet_list_viewport.dart';
import '../../../../categories/domain/entities/category.dart';
import '../../../../categories/domain/entities/category_node.dart';
import '../../../../categories/presentation/cubit/categories_list_cubit.dart';
import '../../../../categories/presentation/cubit/categories_list_state.dart';
import 'category_select_empty_state.dart';
import 'category_select_row.dart';

/// The `Category Select Sheet` (`SfSln`): single-select over the hierarchical
/// category tree of a given [CategoryKind], with a search bar. Built on the
/// shared `Bottom Sheet Base` chrome; a tap on any row resolves the picked
/// [Category] and closes the sheet (no "Aplicar", unlike the multi-select
/// filter sheet). Dismissing the sheet returns `null`.
class CategorySelectSheet extends StatelessWidget {
  const CategorySelectSheet({
    required this.kind,
    required this.selectedId,
    super.key,
  });

  final CategoryKind kind;
  final String? selectedId;

  /// Opens the sheet for [kind] and resolves the chosen category, or `null`
  /// when the user dismisses it without picking.
  static Future<Category?> show(
    BuildContext context, {
    required CategoryKind kind,
    String? selectedId,
  }) =>
      BottomSheetBase.show<Category>(
        context,
        builder: (context) => BlocProvider(
          create: (context) {
            final cubit = getIt<CategoriesListCubit>();
            unawaited(cubit.start(kind: kind));
            return cubit;
          },
          child: CategorySelectSheet(kind: kind, selectedId: selectedId),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      CategorySelectSheetBody(kind: kind, selectedId: selectedId);
}

class CategorySelectSheetBody extends StatefulWidget {
  const CategorySelectSheetBody({
    required this.kind,
    required this.selectedId,
    super.key,
  });

  /// The kind the sheet lists — and the kind a category created via the
  /// inline "+" is born with (bugfix item 13). The picker is expense- or
  /// income-scoped depending on the movement/scheduled-payment type.
  final CategoryKind kind;
  final String? selectedId;

  @override
  State<CategorySelectSheetBody> createState() =>
      _CategorySelectSheetBodyState();
}

class _CategorySelectSheetBodyState extends State<CategorySelectSheetBody> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Bugfix item 13: pushes the full create-category flow (`CategoryFormPage`
  /// via the `newCategory` route) started on the sheet's [CategoryKind], so the
  /// user gets icon, color and — if they want — a parent, not just a name. When
  /// the form saves it pops with the created [Category]; this sheet then pops
  /// with it too, so the picker leaves it selected on return.
  Future<void> _createCategory(BuildContext context) async {
    final navigator = Navigator.of(context);
    final created = await context.push<Category>(
      AppRoutes.newCategory(kind: widget.kind),
    );
    if (created != null) {
      navigator.pop(created);
    }
  }

  /// Filters the tree by name: a root is kept when it or any of its
  /// subcategories match; a matched root keeps all its subcategories, an
  /// unmatched one only the matching ones. Data only — no widgets.
  List<CategoryNode> _visibleNodes(List<CategoryNode> nodes) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return nodes;
    }
    final result = <CategoryNode>[];
    for (final node in nodes) {
      final rootMatches = node.root.name.toLowerCase().contains(query);
      final subs = rootMatches
          ? node.subcategories
          : node.subcategories
              .where((sub) => sub.name.toLowerCase().contains(query))
              .toList();
      if (rootMatches || subs.isNotEmpty) {
        result.add(CategoryNode(root: node.root, subcategories: subs));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final searching = _query.trim().isNotEmpty;

    return BlocBuilder<CategoriesListCubit, CategoriesListState>(
      builder: (context, state) {
        final cubit = context.read<CategoriesListCubit>();
        final nodes = _visibleNodes(state.nodes);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The title (`yHRaI` in `SfSln`) is 17/700 and left aligned,
            // not the theme's 22/500 `titleLarge` centred. The trailing "+"
            // (bugfix item 13) opens the full create-category flow
            // (`CategoryFormPage` / `PZvWF`), mirroring the tag filter sheet's
            // header action but with icon/color/parent, not just a name.
            Row(
              children: [
                Expanded(child: SheetHead(title: l10n.categorySelectTitle)),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: () => _createCategory(context),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    color: colors.primaryOnSoft,
                    tooltip: l10n.categoryFormNewTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surface,
                prefixIcon:
                    Icon(LucideIcons.search, color: colors.textSecondary),
                hintText: l10n.categorySelectSearchHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Loading, "no matches" and the list all live inside the same
            // fixed viewport, so typing in the search field never resizes the
            // sheet.
            SheetListViewport(
              height: 420,
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : nodes.isEmpty
                      ? const Center(child: CategorySelectEmptyState())
                      : ListView(
                          children: [
                            for (final node in nodes)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CategorySelectRow(
                                    category: node.root,
                                    selected: node.root.id == widget.selectedId,
                                    showChevron:
                                        node.hasSubcategories && !searching,
                                    expanded: searching ||
                                        state.isExpanded(node.root.id),
                                    onToggleExpand: () =>
                                        cubit.toggleExpanded(node.root.id),
                                    onTap: () =>
                                        Navigator.of(context).pop(node.root),
                                  ),
                                  // Subcategories slide open/closed in step with the
                                  // root's chevron, on the shared motion tokens.
                                  AnimatedSize(
                                    duration: AppTheme.motionDuration,
                                    curve: AppTheme.motionCurve,
                                    alignment: Alignment.topCenter,
                                    child: (searching ||
                                                state.isExpanded(
                                                    node.root.id)) &&
                                            node.subcategories.isNotEmpty
                                        ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              for (final sub
                                                  in node.subcategories)
                                                CategorySelectRow(
                                                  category: sub,
                                                  selected: sub.id ==
                                                      widget.selectedId,
                                                  isSubcategory: true,
                                                  onTap: () =>
                                                      Navigator.of(context)
                                                          .pop(sub),
                                                ),
                                            ],
                                          )
                                        : const SizedBox(
                                            width: double.infinity),
                                  ),
                                ],
                              ),
                          ],
                        ),
            ),
          ],
        );
      },
    );
  }
}
