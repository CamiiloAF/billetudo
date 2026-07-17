import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
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
  const CategorySelectSheet({required this.selectedId, super.key});

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
          child: CategorySelectSheet(selectedId: selectedId),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      CategorySelectSheetBody(selectedId: selectedId);
}

class CategorySelectSheetBody extends StatefulWidget {
  const CategorySelectSheetBody({required this.selectedId, super.key});

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
    final theme = Theme.of(context);
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
            Text(
              l10n.categorySelectTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
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
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (nodes.isEmpty)
              const CategorySelectEmptyState()
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final node in nodes)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CategorySelectRow(
                            category: node.root,
                            selected: node.root.id == widget.selectedId,
                            showChevron: node.hasSubcategories && !searching,
                            expanded:
                                searching || state.isExpanded(node.root.id),
                            onToggleExpand: () =>
                                cubit.toggleExpanded(node.root.id),
                            onTap: () => Navigator.of(context).pop(node.root),
                          ),
                          // Subcategories slide open/closed in step with the
                          // root's chevron, on the shared motion tokens.
                          AnimatedSize(
                            duration: AppTheme.motionDuration,
                            curve: AppTheme.motionCurve,
                            alignment: Alignment.topCenter,
                            child: (searching ||
                                        state.isExpanded(node.root.id)) &&
                                    node.subcategories.isNotEmpty
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (final sub in node.subcategories)
                                        CategorySelectRow(
                                          category: sub,
                                          selected: sub.id == widget.selectedId,
                                          isSubcategory: true,
                                          onTap: () =>
                                              Navigator.of(context).pop(sub),
                                        ),
                                    ],
                                  )
                                : const SizedBox(width: double.infinity),
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
