import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../domain/entities/budget_scope.dart';
import '../cubit/budget_detail_cubit.dart';
import '../cubit/budget_detail_state.dart';
import '../utils/budget_adjustment_windows.dart';
import '../utils/budget_format.dart';
import '../widgets/budget_activity_row.dart';
import '../widgets/budget_adjustment_entry_card.dart';
import '../widgets/budget_detail_skeleton_view.dart';
import '../widgets/budget_load_more_button.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/budget_scheduled_entry_card.dart';
import '../widgets/budgets_error_view.dart';
import '../widgets/period_stepper_pill.dart';
import '../widgets/sheets/budget_adjust_amount_sheet.dart';
import '../widgets/sheets/budget_detail_actions_sheet.dart';
import '../widgets/sheets/budget_scheduled_sheet.dart';
import '../widgets/sheets/confirm_delete_budget_sheet.dart';

/// The budget detail (`NloPT`, HU-04/HU-05). Hero + activity, with the floating
/// period stepper anchored at the bottom and the actions in the header overflow.
class BudgetDetailPage extends StatelessWidget {
  const BudgetDetailPage({
    required this.onEdit,
    required this.onClosed,
    required this.onOpenTransaction,
    required this.onOpenScheduledPayment,
    super.key,
  });

  final ValueChanged<String> onEdit;

  /// Called after the budget is closed or deleted, to leave the detail.
  final VoidCallback onClosed;

  /// Navigates to the transaction detail page (from an activity row) and
  /// resolves with whatever it popped with (the deleted transaction's id, or
  /// `null`).
  final Future<String?> Function(String id) onOpenTransaction;

  /// Called with a scheduled payment (template) id, from a scheduled row, to
  /// open its detail.
  final ValueChanged<String> onOpenScheduledPayment;

  /// Awaits the detail page's navigation, then — if it deleted something —
  /// offers HU-05's "Deshacer" snackbar via [BudgetDetailCubit].
  Future<void> _openTransaction(BuildContext context, String id) async {
    final deletedId = await onOpenTransaction(id);
    if (deletedId != null && context.mounted) {
      context.read<BudgetDetailCubit>().notifyExternalDelete(deletedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<BudgetDetailCubit, BudgetDetailState>(
          listenWhen: (previous, current) =>
              previous.pendingUndoId != current.pendingUndoId &&
              current.pendingUndoId != null,
          listener: (context, state) {
            final cubit = context.read<BudgetDetailCubit>();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(l10n.transactionsUndoDeletedMessage),
                  action: SnackBarAction(
                    label: l10n.transactionsUndoAction,
                    onPressed: cubit.undoDelete,
                  ),
                  persist: false,
                ),
              );
          },
          builder: (context, state) => Column(
            children: [
              PageHeader(
                title: state.budget?.name ?? '',
                trailing: PageHeaderCircleButton(
                  icon: LucideIcons.ellipsisVertical,
                  background: colors.muted,
                  foreground: colors.textPrimary,
                  tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                  onPressed:
                      state.budget == null ? null : () => _openActions(context),
                ),
              ),
              Expanded(
                child: switch (state.status) {
                  BudgetDetailStatus.loading =>
                    const BudgetDetailSkeletonView(),
                  BudgetDetailStatus.failure => BudgetsErrorView(
                      onRetry: () {},
                    ),
                  BudgetDetailStatus.ready => BudgetDetailBody(
                      state: state,
                      onOpenTransaction: (id) => _openTransaction(context, id),
                      onOpenScheduledPayment: onOpenScheduledPayment,
                      onAdjustAmount: () => _openAdjustAmountSheet(context),
                    ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openActions(BuildContext context) async {
    final cubit = context.read<BudgetDetailCubit>();
    final budget = cubit.state.budget;
    if (budget == null) {
      return;
    }
    final id = budget.id;
    final action = await BudgetDetailActionsSheet.show(
      context,
      budgetName: budget.name,
    );
    if (action == null || !context.mounted) {
      return;
    }
    switch (action) {
      case BudgetDetailAction.edit:
        onEdit(id);
      case BudgetDetailAction.adjustAmount:
        await _openAdjustAmountSheet(context);
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

  /// "Ajustar monto — solo el próximo período": opens the sheet in "crear"
  /// mode from the `⋮` entry point, or in "editar/cancelar" mode — reopened
  /// prefilled — from the detail banner (HU-13).
  Future<void> _openAdjustAmountSheet(BuildContext context) async {
    final cubit = context.read<BudgetDetailCubit>();
    final budget = cubit.state.budget;
    if (budget == null) {
      return;
    }
    final pending = cubit.state.pendingAdjustment;
    final windows = BudgetAdjustmentWindows(budget, DateTime.now());
    final result = await BudgetAdjustAmountSheet.show(
      context,
      currentAmountMinor: budget.amountMinor,
      currency: budget.currency,
      windows: windows,
      pendingAmountMinor: pending?.newAmountMinor,
    );
    if (result == null || !context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case BudgetAdjustAmountApplied(:final newAmountMinor):
        final isEditing = pending != null;
        final actionResult = isEditing
            ? await cubit.updateAmountAdjustment(newAmountMinor)
            : await cubit.scheduleAmountAdjustment(newAmountMinor);
        actionResult.fold(
          (_) {},
          (_) {
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    isEditing
                        ? l10n.budgetAdjustUpdatedSnackbar
                        : l10n.budgetAdjustScheduledSnackbar,
                  ),
                ),
              );
          },
        );
      case BudgetAdjustAmountRemoved():
        final actionResult = await cubit.cancelAmountAdjustment();
        actionResult.fold(
          (_) {},
          (_) {
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.budgetAdjustCancelledSnackbar)),
              );
          },
        );
    }
  }
}

/// The detail content: a scrolling hero + activity under a floating stepper.
class BudgetDetailBody extends StatelessWidget {
  const BudgetDetailBody({
    required this.state,
    required this.onOpenTransaction,
    required this.onOpenScheduledPayment,
    required this.onAdjustAmount,
    super.key,
  });

  final BudgetDetailState state;

  /// Called with a transaction id, from an activity row.
  final ValueChanged<String> onOpenTransaction;

  /// Called with a scheduled payment (template) id, from a scheduled row.
  final ValueChanged<String> onOpenScheduledPayment;

  /// "Ajustar monto — próximo período": opens the sheet in "editar/cancelar"
  /// mode, from the banner (HU-13).
  final VoidCallback onAdjustAmount;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BudgetDetailCubit>();
    final view = state.view;
    final budget = state.budget;
    if (view == null || budget == null) {
      return const SizedBox.shrink();
    }
    final progress = view.progress;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
          children: [
            BudgetDetailHero(state: state),
            // HU-12: the "Programado" entry (`s09qcC`) is its own card under
            // the hero, not part of it — hidden entirely when the window has
            // nothing scheduled (`kLUl7`).
            if (progress.scheduledMinor > 0) ...[
              const SizedBox(height: 16),
              BudgetScheduledEntryCard(
                label: AppLocalizations.of(context).budgetScheduledLabel,
                sub: BudgetFormat.scheduledEntrySub(
                  AppLocalizations.of(context),
                  progress,
                  budget.currency,
                  view.scheduledItems.length,
                ),
                amountLabel: const MoneyFormatter().formatSymbol(
                  progress.scheduledMinor,
                  currencyCode: budget.currency,
                ),
                atRisk: progress.isScheduledOverspendRisk,
                onTap: () => BudgetScheduledSheet.show(
                  context,
                  items: view.scheduledItems,
                  totalMinor: progress.scheduledMinor,
                  currency: budget.currency,
                  onOpenScheduledPayment: onOpenScheduledPayment,
                ),
              ),
            ],
            // "Ajustar monto — próximo período": the pending-fork banner
            // (`AYsw7`/`s0ZlV`), hidden entirely when nothing is scheduled —
            // same convention as the "Programado" card above.
            if (state.pendingAdjustment case final adjustment?) ...[
              const SizedBox(height: 16),
              BudgetAdjustmentEntryCard(
                label: AppLocalizations.of(context).budgetAdjustBannerLabel,
                sub: AppLocalizations.of(context).budgetAdjustBannerSub(
                  const MoneyFormatter().formatSymbol(
                    adjustment.newAmountMinor,
                    currencyCode: budget.currency,
                  ),
                ),
                onTap: onAdjustAmount,
              ),
            ],
            // `QWC08` spaces the hero and the activity by 16, not 24.
            const SizedBox(height: 16),
            BudgetActivitySection(
              state: state,
              onLoadMore: cubit.loadMoreActivity,
              onOpenTransaction: onOpenTransaction,
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: PeriodStepperPill(
            budget: budget,
            window: view.window,
            onPrevious: cubit.previousPeriod,
            onNext: cubit.nextPeriod,
          ),
        ),
      ],
    );
  }
}

/// Compact hero card (`NloPT/j35Yt`): the budget's identity row, "Te quedan $X"
/// and the bar with a single 2-part caption — all inside one `$surface` card,
/// the dominant element of the screen.
class BudgetDetailHero extends StatelessWidget {
  const BudgetDetailHero({required this.state, super.key});

  final BudgetDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final budget = state.budget!;
    final scope = state.scope ?? const BudgetScope.empty();
    final view = state.view!;
    final progress = view.progress;
    final overspent = progress.isOverspent;
    final daysLeft =
        BudgetFormat.daysLeftCaption(l10n, budget, view.window, progress);
    const money = MoneyFormatter();

    final headline = money.formatSymbol(
      overspent ? -progress.remainingMinor : progress.remainingMinor,
      currencyCode: budget.currency,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `NloPT/UOLr6` — the identity row. The name repeats the header on
          // purpose: the card must stand on its own as the budget's object.
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: overspent ? colors.expenseSoft : colors.muted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  CategoryAppearance.iconFor(budget.icon),
                  size: 20,
                  color: overspent ? colors.expense : colors.primaryOnSoft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      BudgetFormat.scopeLabel(l10n, scope),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            overspent ? l10n.budgetOverspentLabel : l10n.budgetRemainingLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: overspent ? colors.expenseText : colors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            headline,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: overspent ? colors.expenseText : colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          BudgetProgressBar(
            fraction: progress.fraction,
            overspent: overspent,
            scheduledFraction: progress.scheduledFraction,
            scheduledAtRisk: progress.isScheduledOverspendRisk,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  BudgetFormat.progressCaption(l10n, progress, budget.currency),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        overspent ? colors.expenseText : colors.textSecondary,
                  ),
                ),
              ),
              // The days left come from the domain's already-computed
              // `progress.daysLeft`, never from `DateTime.now()` in `build`:
              // that made the widget non-deterministic (and printed "Último
              // día" in every golden). Absent on a period that is not the
              // running one.
              if (daysLeft != null) ...[
                const SizedBox(width: 8),
                Text(
                  daysLeft,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          // HU-12's second caption line, e.g. "+ $60.000 programado (llega a
          // 92% si se ejecuta)" (sano) or "... — excedería el presupuesto por
          // $Y" (riesgo, `amber-text`). `null` when the window has nothing
          // scheduled, matching WCAG 1.4.1: the "programado"/riesgo segment
          // is always named in text here, never signalled by the bar's color
          // alone.
          if (BudgetFormat.scheduledCaption(l10n, progress, budget.currency)
              case final scheduledCaption?) ...[
            const SizedBox(height: 8),
            Text(
              scheduledCaption,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: progress.isScheduledOverspendRisk
                    ? colors.amberText
                    : colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The period's activity (`NloPT/R30oao`): the section header with the movement
/// count, the matched expenses and the "Ver más" pill.
class BudgetActivitySection extends StatelessWidget {
  const BudgetActivitySection({
    required this.state,
    required this.onLoadMore,
    required this.onOpenTransaction,
    super.key,
  });

  final BudgetDetailState state;
  final VoidCallback onLoadMore;

  /// Called with a row's transaction id to open its detail.
  final ValueChanged<String> onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final items = state.visibleActivity;
    final total = state.view?.activity.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `NloPT/Nv04I` — title on the left, the period's movement count on
        // the right. The count is the total of the period, not the visible
        // slice, so it does not change as "Ver más" expands the list.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.budgetActivityTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.budgetActivityCount(total),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
          for (final (index, item) in items.indexed) ...[
            if (index > 0) const SizedBox(height: 14),
            BudgetActivityRow(item: item, onTap: onOpenTransaction),
          ],
        if (state.hasMoreActivity) ...[
          const SizedBox(height: 18),
          BudgetLoadMoreButton(onPressed: onLoadMore),
        ],
      ],
    );
  }
}
