import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/date_picker_sheet.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../../../core/widgets/toggle_field.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../scheduled_payments/presentation/utils/scheduled_payment_format.dart';
import '../../../scheduled_payments/presentation/widgets/scheduled_payment_frequency_unit_chips.dart';
import '../../../transactions/presentation/widgets/category_picker/category_quick_picker.dart';
import '../cubit/goal_recurring_contribution_cubit.dart';
import '../cubit/goal_recurring_contribution_state.dart';
import '../utils/goal_format.dart';
import '../widgets/goal_amount_hero_field.dart';
import '../widgets/goal_movement_field_label.dart';
import '../widgets/goal_movement_selector_box.dart';
import '../widgets/sheets/goal_account_picker_sheet.dart';

/// HU-16 "Crear uno nuevo" (`ebcqG`/`G2AfJ`): the config for a brand-new
/// scheduled payment linked to the goal — cuenta origen, "¿Incluir en tu
/// presupuesto?" toggle with the "Ahorros" seed preselected, frecuencia and a
/// fixed monto. Structurally a clone of Deudas' "Configurar cuota" (same
/// underlying template shape, just linked via `goalId` instead of `debtId`),
/// kept self-contained in this feature per HU-16's cross-feature-agnostic
/// precedent (`GoalContributionSheet`, `GoalLinkModePage`).
class GoalRecurringContributionFormPage extends StatelessWidget {
  const GoalRecurringContributionFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoalRecurringContributionCubit,
        GoalRecurringContributionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == GoalRecurringContributionStatus.saved) {
          Navigator.of(context).pop(state.createdScheduledPaymentId);
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final colors = context.colors;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                GoalRecurringContributionFormHeader(state: state),
                Expanded(
                  child: state.status == GoalRecurringContributionStatus.loading
                      ? const Center(child: CircularProgressIndicator())
                      : GoalRecurringContributionFormBody(state: state),
                ),
                if (state.failure != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l10n.goalRecurringContributionSaveError,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.expenseText),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GoalRecurringContributionFormHeader extends StatelessWidget {
  const GoalRecurringContributionFormHeader({required this.state, super.key});

  final GoalRecurringContributionState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          PageHeaderCircleButton(
            icon: LucideIcons.x,
            background: colors.muted,
            foreground: colors.textPrimary,
            tooltip: l10n.commonCancel,
            onPressed: Navigator.of(context).pop,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  l10n.goalRecurringContributionFormTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  state.goalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          PageHeaderCircleButton(
            icon: LucideIcons.check,
            background: state.canSubmitCreate ? colors.primary : colors.muted,
            foreground:
                state.canSubmitCreate ? colors.onPrimary : colors.textSecondary,
            tooltip: l10n.goalRecurringContributionSubmitCta,
            onPressed: state.canSubmitCreate
                ? () => context
                    .read<GoalRecurringContributionCubit>()
                    .submitCreate()
                : null,
          ),
        ],
      ),
    );
  }
}

class GoalRecurringContributionFormBody extends StatelessWidget {
  const GoalRecurringContributionFormBody({required this.state, super.key});

  final GoalRecurringContributionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<GoalRecurringContributionCubit>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        GoalAmountHeroField(
          fieldKey: const ValueKey('goal-recurring-contribution-amount'),
          label: l10n.goalRecurringContributionAmountLabel,
          currency: state.currency,
          initialAmountMinor: state.amountMinor,
          onChanged: cubit.amountChanged,
          boxed: true,
        ),
        const SizedBox(height: 16),
        GoalMovementFieldLabel(
          text: l10n.goalRecurringContributionSourceAccountLabel,
        ),
        const SizedBox(height: 6),
        GoalMovementSelectorBox(
          icon: LucideIcons.wallet,
          value: state.selectedAccount == null
              ? l10n.goalAccountFieldPlaceholder
              : '${state.selectedAccount!.account.name} · '
                  '${GoalFormat.amount(
                  state.selectedAccount!.balance.balanceMinor,
                  state.selectedAccount!.account.currency,
                )}',
          onTap: () => unawaited(_pickAccount(context, cubit, state)),
        ),
        const SizedBox(height: 16),
        ToggleField(
          icon: LucideIcons.chartPie,
          label: l10n.goalBudgetToggleLabel,
          value: state.countsInBudget,
          hint: state.countsInBudget
              ? l10n.goalBudgetToggleHintOnContribute
              : l10n.goalBudgetToggleHintOff,
          onChanged: cubit.toggleCountsInBudget,
        ),
        if (state.countsInBudget) ...[
          const SizedBox(height: 14),
          CategoryQuickPicker(
            kind: CategoryKind.expense,
            selectedId: state.categoryId,
            onSelected: (category) => cubit.categoryChanged(category.id),
          ),
        ],
        const SizedBox(height: 16),
        GoalMovementFieldLabel(
          text: l10n.goalRecurringContributionFrequencyLabel,
        ),
        const SizedBox(height: 6),
        ScheduledPaymentFrequencyUnitChips(
          frequency: state.frequency,
          onChanged: cubit.frequencyChanged,
        ),
        const SizedBox(height: 16),
        GoalMovementFieldLabel(text: l10n.scheduledPaymentFormNextDateLabel),
        const SizedBox(height: 6),
        GoalMovementSelectorBox(
          icon: LucideIcons.calendar,
          value: ScheduledPaymentFormat.dateLabel(context, state.nextDate),
          onTap: () => unawaited(_pickDate(context, cubit, state.nextDate)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.calendarClock,
                size: 18,
                color: context.colors.primaryOnSoft,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.goalRecurringContributionBanner,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: context.colors.hintText),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAccount(
    BuildContext context,
    GoalRecurringContributionCubit cubit,
    GoalRecurringContributionState state,
  ) async {
    if (state.accounts.isEmpty) {
      return;
    }
    final picked = await GoalAccountPickerSheet.show(
      context,
      accounts: state.accounts,
      selectedId: state.selectedAccountId,
    );
    if (picked != null) {
      cubit.accountSelected(picked.account.id);
    }
  }

  Future<void> _pickDate(
    BuildContext context,
    GoalRecurringContributionCubit cubit,
    DateTime current,
  ) async {
    final picked = await DatePickerSheet.show(context, initialDate: current);
    if (picked != null) {
      cubit.nextDateChanged(picked);
    }
  }
}
