import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../accounts/presentation/widgets/empty_state.dart';
import '../cubit/archived_budgets_cubit.dart';
import '../cubit/archived_budgets_state.dart';
import '../widgets/archived_budget_row.dart';
import '../widgets/budget_skeleton_row.dart';
import '../widgets/budgets_error_view.dart';

/// The closed-budgets history (`KfPyk`, HU-11). Reached from the list overflow.
class ArchivedBudgetsPage extends StatelessWidget {
  const ArchivedBudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetsHistoryTitle)),
      body: SafeArea(
        child: BlocBuilder<ArchivedBudgetsCubit, ArchivedBudgetsState>(
          builder: (context, state) => switch (state.status) {
            ArchivedBudgetsStatus.loading => const ArchivedBudgetsLoadingView(),
            ArchivedBudgetsStatus.failure => BudgetsErrorView(
                onRetry: context.read<ArchivedBudgetsCubit>().start,
              ),
            ArchivedBudgetsStatus.ready when state.budgets.isEmpty =>
              const ArchivedBudgetsEmptyView(),
            ArchivedBudgetsStatus.ready => ArchivedBudgetsListView(state: state),
          },
        ),
      ),
    );
  }
}

class ArchivedBudgetsLoadingView extends StatelessWidget {
  const ArchivedBudgetsLoadingView({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: AppLocalizations.of(context).budgetsHistoryLoading,
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) => const BudgetSkeletonRow(),
        ),
      );
}

class ArchivedBudgetsEmptyView extends StatelessWidget {
  const ArchivedBudgetsEmptyView({super.key});

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: LucideIcons.archive,
        message: AppLocalizations.of(context).budgetsHistoryEmpty,
      );
}

class ArchivedBudgetsListView extends StatelessWidget {
  const ArchivedBudgetsListView({required this.state, super.key});

  final ArchivedBudgetsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ArchivedBudgetsCubit>();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: state.budgets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final entry = state.budgets[index];
        return ArchivedBudgetRow(
          entry: entry,
          onReactivate: () => cubit.reactivate(entry.budget.id),
        );
      },
    );
  }
}
