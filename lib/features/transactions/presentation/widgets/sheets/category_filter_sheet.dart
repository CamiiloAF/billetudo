import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../categories/domain/entities/category_node.dart';
import '../../cubit/category_filter_cubit.dart';

/// HU-06's category filter sheet: both trees (income and expense), with the
/// symmetric root/subcategory toggle. Only takes effect on "Aplicar".
class CategoryFilterSheet extends StatelessWidget {
  const CategoryFilterSheet({required this.initialSelected, super.key});

  final Set<String> initialSelected;

  static Future<Set<String>?> show(
    BuildContext context, {
    required Set<String> initialSelected,
  }) =>
      showModalBottomSheet<Set<String>>(
        context: context,
        isScrollControlled: true,
        builder: (context) =>
            CategoryFilterSheet(initialSelected: initialSelected),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<CategoryFilterCubit>();
        unawaited(cubit.start(initialSelected));
        return cubit;
      },
      child: const CategoryFilterSheetBody(),
    );
  }
}

class CategoryFilterSheetBody extends StatelessWidget {
  const CategoryFilterSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<CategoryFilterCubit, CategoryFilterState>(
      builder: (context, state) {
        final cubit = context.read<CategoryFilterCubit>();
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.categoryFilterSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final node in [
                        ...state.expenseNodes,
                        ...state.incomeNodes
                      ])
                        CategoryNodeTile(
                          node: node,
                          selected: state.selected,
                          onToggleRoot: () => cubit.toggleRootCategory(node),
                          onToggleSubcategory: cubit.toggleSubcategory,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(state.selected),
                  child: Text(l10n.commonApply),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CategoryNodeTile extends StatelessWidget {
  const CategoryNodeTile({
    required this.node,
    required this.selected,
    required this.onToggleRoot,
    required this.onToggleSubcategory,
    super.key,
  });

  final CategoryNode node;
  final Set<String> selected;
  final VoidCallback onToggleRoot;
  final ValueChanged<String> onToggleSubcategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CheckboxListTile(
          value: selected.contains(node.root.id),
          onChanged: (_) => onToggleRoot(),
          title: Text(node.root.name),
        ),
        for (final subcategory in node.subcategories)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: CheckboxListTile(
              value: selected.contains(subcategory.id),
              onChanged: (_) => onToggleSubcategory(subcategory.id),
              title: Text(subcategory.name),
            ),
          ),
      ],
    );
  }
}
