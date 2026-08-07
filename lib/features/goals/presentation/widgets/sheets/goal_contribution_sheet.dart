import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/date_picker_sheet.dart';
import '../../../../../core/widgets/note_autocomplete_field.dart';
import '../../../../../core/widgets/toggle_field.dart';
import '../../../../accounts/presentation/utils/show_account_gate_if_needed.dart';
import '../../../../accounts/presentation/widgets/account_gate_copy.dart';
import '../../../../categories/domain/entities/category.dart';
import '../../../../transactions/presentation/widgets/category_picker/category_quick_picker.dart';
import '../../../../tutorials/domain/entities/tutorial_key.dart';
import '../../../../tutorials/presentation/widgets/tutorial_auto_show.dart';
import '../../../domain/entities/goal_contribution.dart';
import '../../cubit/goal_contribution_cubit.dart';
import '../../cubit/goal_contribution_state.dart';
import '../../utils/goal_format.dart';
import '../currency_pill.dart';
import '../goal_amount_hero_field.dart';
import '../goal_movement_field_label.dart';
import '../goal_movement_selector_box.dart';
import 'goal_account_picker_sheet.dart';

/// Registrar aporte/retiro (HU-03/HU-04): the goal's own name in the title,
/// the amount row with its currency chip, the "¿Mover dinero de una cuenta?"
/// toggle (`ZgR6U`/`BETeo`/`GK69y` aportar, `jFfBT`/`CpLy8`/`DiDwa` retirar) —
/// OFF writes a pure tracking [GoalContribution] row; ON reveals the account
/// picker and, once chosen, the "¿Incluir en tu presupuesto?" toggle and its
/// category picker, and writes a real transfer instead. An optional note,
/// fecha, "Enlazar un movimiento" (attributes an already-registered
/// transaction instead, `ZgR6U`'s `BoK6S`) and — for a retiro — the hard cap
/// and "Usar todo" chip.
///
/// Resolves to the milestone threshold newly crossed (HU-06), or `null`,
/// once the save settles — the caller decides whether to celebrate. Also
/// resolves to `null` when the sheet closes because the user chose to
/// enlazar a movement instead (the link-mode screen owns that flow after
/// that point).
class GoalContributionSheet extends StatelessWidget {
  const GoalContributionSheet({super.key});

  static Future<int?> show(
    BuildContext context, {
    required String goalId,
    required String goalName,
    required GoalMovementDirection direction,
    required String currency,
    int maxWithdrawableMinor = 0,
    bool hasLinkedAccount = true,
    int initialAmountMinor = 0,
  }) =>
      BottomSheetBase.show<int?>(
        context,
        builder: (context) => BlocProvider(
          create: (context) {
            final cubit = getIt<GoalContributionCubit>();
            unawaited(
              cubit.start(
                goalId: goalId,
                goalName: goalName,
                direction: direction,
                currency: currency,
                maxWithdrawableMinor: maxWithdrawableMinor,
                hasLinkedAccount: hasLinkedAccount,
                initialAmountMinor: initialAmountMinor,
              ),
            );
            return cubit;
          },
          child: const GoalContributionSheet(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoalContributionCubit, GoalContributionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == GoalContributionStatus.saved) {
          Navigator.of(context).pop(state.milestoneCrossed);
        }
      },
      builder: (context, state) => GoalContributionSheetBody(state: state),
    );
  }
}

class GoalContributionSheetBody extends StatelessWidget {
  const GoalContributionSheetBody({required this.state, super.key});

  final GoalContributionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final cubit = context.read<GoalContributionCubit>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isWithdrawal
                      ? l10n.goalWithdrawTitleWithName(state.goalName)
                      : l10n.goalContributeTitleWithName(state.goalName),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.isWithdrawal
                      ? l10n.goalWithdrawSubtitle
                      : l10n.goalContributeSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                GoalAmountHeroField(
                  fieldKey: const ValueKey('goal-amount-movement'),
                  label: state.isWithdrawal
                      ? l10n.goalWithdrawAmountLabel
                      : l10n.goalContributeAmountLabel,
                  currency: state.currency,
                  initialAmountMinor: state.amountMinor,
                  onChanged: cubit.amountChanged,
                  autofocus: true,
                  compact: true,
                  compactTrailing: CurrencyPill(
                    label: state.currency,
                    locked: false,
                  ),
                  errorText: state.isWithdrawal &&
                          state.amountMinor > state.maxWithdrawableMinor
                      ? l10n.goalWithdrawErrorExceedsSaved
                      : null,
                ),
                if (state.isWithdrawal) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.goalWithdrawAvailableLabel(
                            GoalFormat.amount(
                              state.maxWithdrawableMinor,
                              state.currency,
                            ),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          key: const ValueKey('goal-withdraw-use-max'),
                          onTap: cubit.useMax,
                          child: Text(
                            l10n.goalWithdrawUseMaxCta,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.primaryOnSoftStrong,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (state.hasLinkedAccount) ...[
                  const SizedBox(height: 10),
                  // First time this control renders, its own minitutorial
                  // explains earmarking vs. an actual transfer
                  // (`docs/requirements/16-minitutoriales.md` HU-02).
                  TutorialAutoShow(
                    tutorialKey: TutorialKey.goalContributionToggle,
                    child: ToggleField(
                      icon: LucideIcons.arrowLeftRight,
                      label: l10n.goalMoveFundsToggleLabel,
                      value: state.moveMoney,
                      hint: _moveFundsHint(l10n, state),
                      onChanged: (value) => unawaited(
                        _toggleMoveMoney(context, cubit, value),
                      ),
                    ),
                  ),
                  if (state.moveMoney) ...[
                    const SizedBox(height: 14),
                    GoalMovementFieldLabel(
                      text: state.isWithdrawal
                          ? l10n.goalWithdrawDestinationAccountLabel
                          : l10n.goalContributeSourceAccountLabel,
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
                      onTap: () =>
                          unawaited(_pickAccount(context, cubit, state)),
                    ),
                    const SizedBox(height: 14),
                    ToggleField(
                      icon: LucideIcons.chartPie,
                      label: l10n.goalBudgetToggleLabel,
                      value: state.countsInBudget,
                      hint: state.countsInBudget
                          ? (state.isWithdrawal
                              ? l10n.goalBudgetToggleHintOnWithdraw
                              : l10n.goalBudgetToggleHintOnContribute)
                          : l10n.goalBudgetToggleHintOff,
                      onChanged: cubit.toggleCountsInBudget,
                    ),
                    if (state.countsInBudget) ...[
                      const SizedBox(height: 14),
                      CategoryQuickPicker(
                        kind: CategoryKind.expense,
                        selectedId: state.categoryId,
                        onSelected: (category) =>
                            cubit.categoryChanged(category.id),
                      ),
                    ],
                  ],
                ],
                const SizedBox(height: 14),
                GoalMovementFieldLabel(text: l10n.goalMovementDateLabel),
                const SizedBox(height: 6),
                GoalMovementSelectorBox(
                  icon: LucideIcons.calendar,
                  value: GoalFormat.relativeDate(context, l10n, state.date),
                  onTap: () => unawaited(_pickDate(context, cubit, state.date)),
                ),
                const SizedBox(height: 14),
                GoalMovementFieldLabel(text: l10n.goalMovementNoteLabel),
                const SizedBox(height: 6),
                NoteAutocompleteField(
                  key: const ValueKey('goal-movement-note'),
                  initialValue: state.note,
                  hint: l10n.goalMovementNoteHint,
                  onChanged: cubit.noteChanged,
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton.icon(
                    key: const ValueKey('goal-movement-link-transaction'),
                    onPressed: () => unawaited(_openLinkMode(context, state)),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primaryOnSoftStrong,
                    ),
                    icon: const Icon(LucideIcons.link2, size: 16),
                    label: Text(
                      l10n.goalLinkTransactionCta,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryOnSoftStrong,
                      ),
                    ),
                  ),
                ),
                if (state.failure != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.goalMovementError,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.expenseText),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('goal-movement-submit'),
            onPressed: state.canSubmit ? cubit.submit : null,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(
              state.isWithdrawal
                  ? l10n.goalWithdrawCta
                  : l10n.goalContributeCta,
            ),
          ),
        ),
      ],
    );
  }

  /// "¿Mover dinero de una cuenta?" hint: OFF explains the movement stays
  /// tracking-only; ON (billetudo.pen `BETeo`/`GK69y`/`CpLy8`/`DiDwa`) explains
  /// the transfer it will create — a shorter copy once the transfer is also
  /// presupuestable (contribute only; withdraw uses the same copy either way).
  /// Only called when `state.hasLinkedAccount` is true — the toggle itself is
  /// hidden otherwise, since a goal with no linked account has nowhere for a
  /// transfer to land.
  String _moveFundsHint(AppLocalizations l10n, GoalContributionState state) {
    if (!state.moveMoney) {
      return state.isWithdrawal
          ? l10n.goalMoveFundsToggleHintWithdraw
          : l10n.goalMoveFundsToggleHintContribute;
    }
    if (state.isWithdrawal) {
      return l10n.goalMoveFundsToggleHintWithdrawOn;
    }
    return state.countsInBudget
        ? l10n.goalMoveFundsToggleHintContributeOnBudget
        : l10n.goalMoveFundsToggleHintContributeOn;
  }

  Future<void> _pickDate(
    BuildContext context,
    GoalContributionCubit cubit,
    DateTime current,
  ) async {
    final picked = await DatePickerSheet.show(
      context,
      initialDate: current,
      disabledAfter: DateTime.now(),
    );
    if (picked != null) {
      cubit.dateChanged(picked);
    }
  }

  /// HU-03/HU-04 gated by `15-gate-cuenta.md`: turning the toggle to Sí
  /// generates a real transfer, so without any active account this opens the
  /// bridge sheet instead of just revealing an account selector that would
  /// have nothing to pick.
  Future<void> _toggleMoveMoney(
    BuildContext context,
    GoalContributionCubit cubit,
    bool value,
  ) async {
    if (!value) {
      cubit.toggleMoveMoney(false);
      return;
    }
    final hadAccounts = cubit.state.accounts.isNotEmpty;
    final canProceed = await showAccountGateIfNeeded(
      context,
      AccountGateSurface.goalMovement,
    );
    if (!canProceed) {
      return;
    }
    // The bridge sheet only opens when `state.accounts` was empty; a fresh
    // account was created in the meantime, so the cubit's list is stale
    // until reloaded — otherwise the toggle flips on but the account picker
    // it reveals still has nothing to show.
    if (!hadAccounts) {
      await cubit.refreshAccounts();
    }
    cubit.toggleMoveMoney(true);
  }

  Future<void> _pickAccount(
    BuildContext context,
    GoalContributionCubit cubit,
    GoalContributionState state,
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
      cubit.selectAccount(picked.account.id);
    }
  }

  /// "Enlazar un movimiento" (HU-03): closes this sheet — a link attributes
  /// an existing transaction instead, so there is nothing left here to
  /// submit — then pushes Movimientos in link mode. The router is captured
  /// before popping, the same precedent as Pagos Programados' own
  /// "Editar" exit from a confirmation sheet.
  Future<void> _openLinkMode(
    BuildContext context,
    GoalContributionState state,
  ) async {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    await router.push<void>(
      AppRoutes.linkTransactionToGoal(state.goalId),
      extra: GoalLinkContext(
        goalId: state.goalId,
        goalName: state.goalName,
        direction: state.direction,
      ),
    );
  }
}
