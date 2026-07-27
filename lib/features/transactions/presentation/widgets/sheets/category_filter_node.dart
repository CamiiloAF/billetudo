import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../categories/domain/entities/category_node.dart';
import '../../cubit/category_filter_cubit.dart';
import 'category_filter_row.dart';

/// One root and its subcategories, sliding open/closed with the root's
/// chevron in step with the shared motion tokens.
class CategoryFilterNode extends StatelessWidget {
  const CategoryFilterNode({
    required this.node,
    required this.state,
    required this.cubit,
    super.key,
  });

  final CategoryNode node;
  final CategoryFilterState state;
  final CategoryFilterCubit cubit;

  @override
  Widget build(BuildContext context) {
    final expanded = state.isExpanded(node.root.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CategoryFilterRow(
            category: node.root,
            selected: state.selected.contains(node.root.id),
            subcategoryCount: node.subcategoryCount,
            expanded: expanded,
            onToggleSelected: () => cubit.toggleRootCategory(node),
            onToggleExpand: node.hasSubcategories
                ? () => cubit.toggleExpanded(node.root.id)
                : null,
          ),
          AnimatedSize(
            duration: AppTheme.motionDuration,
            curve: AppTheme.motionCurve,
            alignment: Alignment.topCenter,
            child: expanded && node.hasSubcategories
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final subcategory in node.subcategories)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: CategoryFilterRow(
                            category: subcategory,
                            selected: state.selected.contains(subcategory.id),
                            isSubcategory: true,
                            onToggleSelected: () =>
                                cubit.toggleSubcategory(subcategory.id),
                          ),
                        ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
