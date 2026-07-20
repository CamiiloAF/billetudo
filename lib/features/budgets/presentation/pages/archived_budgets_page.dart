import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/archived_budgets_cubit.dart';
import '../cubit/archived_budgets_state.dart';
import '../widgets/archived_budget_row.dart';
import '../widgets/archived_budget_skeleton_row.dart';
import '../widgets/archived_budgets_subheader.dart';
import '../widgets/budgets_error_view.dart';

/// The closed-budgets history (`KfPyk`, HU-11). Reached from the list overflow.
class ArchivedBudgetsPage extends StatelessWidget {
  const ArchivedBudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.budgetsHistoryTitle),
            Expanded(
              child: BlocBuilder<ArchivedBudgetsCubit, ArchivedBudgetsState>(
                builder: (context, state) => switch (state.status) {
                  ArchivedBudgetsStatus.loading =>
                    const ArchivedBudgetsLoadingView(),
                  ArchivedBudgetsStatus.failure => BudgetsErrorView(
                      onRetry: context.read<ArchivedBudgetsCubit>().start,
                    ),
                  ArchivedBudgetsStatus.ready when state.budgets.isEmpty =>
                    const ArchivedBudgetsEmptyView(),
                  ArchivedBudgetsStatus.ready =>
                    ArchivedBudgetsListView(state: state),
                },
              ),
            ),
          ],
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          // `rI2bL/KqkhS` shows 4 placeholder cards; the subheader is the
          // extra first item, so the count is 5.
          itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) => index == 0
              ? const ArchivedBudgetsSubheader()
              : const ArchivedBudgetSkeletonRow(),
        ),
      );
}

class ArchivedBudgetsEmptyView extends StatelessWidget {
  const ArchivedBudgetsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The subheader stays anchored under the header (it explains the screen
    // even with nothing in it) and the empty block centers in what is left,
    // the same shape as the budgets list's own empty state (`Zqsi1`) — which
    // also carries a second line, so this one does too.
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: ArchivedBudgetsSubheader(),
        ),
        Expanded(
          child: EmptyState(
            icon: LucideIcons.archive,
            message: l10n.budgetsHistoryEmpty,
            description: l10n.budgetsHistoryEmptyDescription,
            descriptionSpacing: 6,
          ),
        ),
      ],
    );
  }
}

class ArchivedBudgetsListView extends StatelessWidget {
  const ArchivedBudgetsListView({required this.state, super.key});

  final ArchivedBudgetsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ArchivedBudgetsCubit>();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: state.budgets.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const ArchivedBudgetsSubheader();
        }
        final entry = state.budgets[index - 1];
        return ArchivedBudgetRow(
          entry: entry,
          onReactivate: () => cubit.reactivate(entry.budget.id),
        );
      },
    );
  }
}
