import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/category_filter_cubit.dart';
import 'category_filter_header_action.dart';
import 'category_filter_node.dart';

/// HU-06's category filter sheet (`q0CTl`/`NZbsD`): both trees (income and
/// expense), with the symmetric root/subcategory toggle. Only takes effect on
/// "Aplicar".
class CategoryFilterSheet extends StatelessWidget {
  const CategoryFilterSheet({required this.initialSelected, super.key});

  final Set<String> initialSelected;

  static Future<Set<String>?> show(
    BuildContext context, {
    required Set<String> initialSelected,
  }) =>
      BottomSheetBase.show<Set<String>>(
        context,
        builder: (context) => BlocProvider(
          create: (context) {
            final cubit = getIt<CategoryFilterCubit>();
            unawaited(cubit.start(initialSelected));
            return cubit;
          },
          child: const CategoryFilterSheetBody(),
        ),
      );

  @override
  Widget build(BuildContext context) => const CategoryFilterSheetBody();
}

class CategoryFilterSheetBody extends StatelessWidget {
  const CategoryFilterSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    return BlocBuilder<CategoryFilterCubit, CategoryFilterState>(
      builder: (context, state) {
        final cubit = context.read<CategoryFilterCubit>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.categoryFilterSheetTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                CategoryFilterHeaderAction(
                  label: l10n.accountFilterSelectAll,
                  onTap: cubit.selectAll,
                ),
                Text(
                  ' · ',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: colors.textSecondary),
                ),
                CategoryFilterHeaderAction(
                  label: l10n.accountFilterSelectNone,
                  onTap: cubit.selectNone,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final node in [
                    ...state.expenseNodes,
                    ...state.incomeNodes,
                  ])
                    CategoryFilterNode(
                      node: node,
                      state: state,
                      cubit: cubit,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(state.selected),
                child: Text(l10n.commonApply),
              ),
            ),
          ],
        );
      },
    );
  }
}
