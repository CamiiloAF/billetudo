import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../cubit/budget_detail_cubit.dart';
import '../cubit/budget_detail_state.dart';
import '../utils/budget_format.dart';
import '../widgets/budget_activity_row.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/budgets_error_view.dart';
import '../widgets/period_stepper_pill.dart';
import '../widgets/sheets/budget_detail_actions_sheet.dart';
import '../widgets/sheets/confirm_delete_budget_sheet.dart';

/// The budget detail (`NloPT`, HU-04/HU-05). Hero + activity, with the floating
/// period stepper anchored at the bottom and the actions in the header overflow.
class BudgetDetailPage extends StatelessWidget {
  const BudgetDetailPage({
    required this.onEdit,
    required this.onClosed,
    required this.onOpenInTransactions,
    super.key,
  });

  final ValueChanged<String> onEdit;

  /// Called after the budget is closed or deleted, to leave the detail.
  final VoidCallback onClosed;
  final VoidCallback onOpenInTransactions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          BlocBuilder<BudgetDetailCubit, BudgetDetailState>(
            builder: (context, state) => IconButton(
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              icon: const Icon(LucideIcons.ellipsisVertical),
              onPressed: state.budget == null
                  ? null
                  : () => _openActions(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<BudgetDetailCubit, BudgetDetailState>(
          builder: (context, state) => switch (state.status) {
            BudgetDetailStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            BudgetDetailStatus.failure => BudgetsErrorView(
                onRetry: () {},
              ),
            BudgetDetailStatus.ready => BudgetDetailBody(
                state: state,
                onOpenInTransactions: onOpenInTransactions,
              ),
          },
        ),
      ),
    );
  }

  Future<void> _openActions(BuildContext context) async {
    final cubit = context.read<BudgetDetailCubit>();
    final id = cubit.state.budget?.id;
    if (id == null) {
      return;
    }
    final action = await BudgetDetailActionsSheet.show(context);
    if (action == null || !context.mounted) {
      return;
    }
    switch (action) {
      case BudgetDetailAction.edit:
        onEdit(id);
      case BudgetDetailAction.close:
        await cubit.closeToHistory();
        onClosed();
      case BudgetDetailAction.delete:
        final confirmed = await ConfirmDeleteBudgetSheet.show(context);
        if (confirmed == true) {
          await cubit.delete();
          onClosed();
        }
    }
  }
}

/// The detail content: a scrolling hero + activity under a floating stepper.
class BudgetDetailBody extends StatelessWidget {
  const BudgetDetailBody({
    required this.state,
    required this.onOpenInTransactions,
    super.key,
  });

  final BudgetDetailState state;
  final VoidCallback onOpenInTransactions;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BudgetDetailCubit>();
    final view = state.view;
    if (view == null || state.budget == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: [
            BudgetDetailHero(state: state),
            const SizedBox(height: 24),
            BudgetActivitySection(
              state: state,
              onLoadMore: cubit.loadMoreActivity,
              onOpenInTransactions: onOpenInTransactions,
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: PeriodStepperPill(
            window: view.window,
            onPrevious: cubit.previousPeriod,
            onNext: cubit.nextPeriod,
          ),
        ),
      ],
    );
  }
}

/// Compact hero: "Te quedan $X" + bar + a single 2-part caption.
class BudgetDetailHero extends StatelessWidget {
  const BudgetDetailHero({required this.state, super.key});

  final BudgetDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final budget = state.budget!;
    final progress = state.view!.progress;
    final window = state.view!.window;
    final overspent = progress.isOverspent;
    const money = MoneyFormatter();

    final headline = money.format(
      overspent ? -progress.remainingMinor : progress.remainingMinor,
      currencyCode: budget.currency,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          budget.name,
          style: theme.textTheme.titleMedium
              ?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 12),
        Text(
          overspent ? l10n.budgetOverspentLabel : l10n.budgetRemainingLabel,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          headline,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: overspent ? colors.expenseText : colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        BudgetProgressBar(fraction: progress.fraction, overspent: overspent),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                BudgetFormat.progressCaption(l10n, progress, budget.currency),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: overspent ? colors.expenseText : colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.budgetDaysLeft(window.daysLeftFrom(DateTime.now())),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

/// The period's activity: matched expenses, "Cargar más" and the secondary
/// "Abrir en Movimientos ›" link.
class BudgetActivitySection extends StatelessWidget {
  const BudgetActivitySection({
    required this.state,
    required this.onLoadMore,
    required this.onOpenInTransactions,
    super.key,
  });

  final BudgetDetailState state;
  final VoidCallback onLoadMore;
  final VoidCallback onOpenInTransactions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final items = state.visibleActivity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.budgetActivityTitle,
              style: theme.textTheme.titleSmall,
            ),
            TextButton(
              onPressed: onOpenInTransactions,
              child: Text(l10n.budgetOpenInTransactions),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l10n.budgetActivityEmpty,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
            ),
          )
        else
          for (final item in items) ...[
            BudgetActivityRow(item: item),
            const SizedBox(height: 10),
          ],
        if (state.hasMoreActivity)
          Center(
            child: TextButton(
              onPressed: onLoadMore,
              child: Text(l10n.budgetLoadMore),
            ),
          ),
      ],
    );
  }
}
