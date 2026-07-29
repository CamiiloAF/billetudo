import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../transactions/presentation/widgets/detail_actions_row.dart';
import '../../../domain/entities/goal_contribution.dart';
import '../../../domain/entities/goal_movement_accounts.dart';
import '../../cubit/goal_movement_detail_cubit.dart';
import '../../cubit/goal_movement_detail_state.dart';
import '../../utils/goal_format.dart';
import '../../utils/goal_movement_delete_copy.dart';
import 'confirm_delete_goal_movement_sheet.dart';
import 'edit_goal_movement_sheet.dart';

/// The movement detail sheet (`N8Dv2e`): amount + kind, then "Fecha" always,
/// "Cuenta de origen"/"Transferencia" only for a money-moving movement, and
/// "Nota" when present. Editar/Eliminar always show together
/// (`DetailActionsRow`): for a money-moving movement, Editar opens the
/// linked transaction (unwinding the transfer requires editing it, not this
/// row); for a tracking-only one, Editar opens `EditGoalMovementSheet` to
/// rewrite monto/fecha/nota of that same row in place. Eliminar opens
/// `ConfirmDeleteGoalMovementSheet` with the right copy variant and, once
/// confirmed, deletes the movement.
///
/// Resolves to `true` once the movement was actually deleted, so the caller
/// (already subscribed to the goal detail stream) can pop further if needed.
class GoalMovementDetailSheet extends StatelessWidget {
  const GoalMovementDetailSheet({
    required this.movement,
    required this.currency,
    required this.goalName,
    required this.goalCompleted,
    this.onOpenTransaction,
    super.key,
  });

  final GoalContribution movement;
  final String currency;
  final String goalName;
  final bool goalCompleted;
  final ValueChanged<String>? onOpenTransaction;

  static Future<bool?> show(
    BuildContext context, {
    required GoalContribution movement,
    required String currency,
    required String goalName,
    required bool goalCompleted,
    ValueChanged<String>? onOpenTransaction,
  }) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) => BlocProvider(
          create: (context) {
            final cubit = getIt<GoalMovementDetailCubit>();
            unawaited(cubit.start(movement));
            return cubit;
          },
          child: GoalMovementDetailSheet(
            movement: movement,
            currency: currency,
            goalName: goalName,
            goalCompleted: goalCompleted,
            onOpenTransaction: onOpenTransaction,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isWithdrawal = movement.direction == GoalMovementDirection.withdrawal;

    return BlocBuilder<GoalMovementDetailCubit, GoalMovementDetailState>(
      builder: (context, state) {
        final loadingAccounts = movement.movedMoney &&
            state.status == GoalMovementDetailStatus.loading;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.goalMovementDetailTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.goalMovementDetailHint,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isWithdrawal ? colors.surface : colors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isWithdrawal
                          ? LucideIcons.arrowDown
                          : LucideIcons.arrowUp,
                      size: 20,
                      color: isWithdrawal
                          ? colors.textSecondary
                          : colors.primaryOnSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWithdrawal
                              ? l10n.goalMovementWithdrawal
                              : l10n.goalMovementContribution,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          GoalFormat.signedAmount(movement, currency),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (loadingAccounts)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              GoalMovementDetailsCard(
                movement: movement,
                accounts: state.accounts,
              ),
            const SizedBox(height: 14),
            DetailActionsRow(
              editLabel: l10n.commonEdit,
              deleteLabel: l10n.commonDelete,
              onEdit: () => unawaited(_edit(context)),
              onDelete: () => unawaited(_confirmDelete(context, state)),
            ),
          ],
        );
      },
    );
  }

  /// With a `transactionId`, opens the linked transaction (unchanged
  /// behaviour); otherwise pops this sheet and opens `EditGoalMovementSheet`
  /// to rewrite this movement's monto/fecha/nota in place.
  Future<void> _edit(BuildContext context) async {
    final transactionId = movement.transactionId;
    Navigator.of(context).pop();
    if (transactionId != null) {
      onOpenTransaction?.call(transactionId);
      return;
    }
    if (!context.mounted) {
      return;
    }
    await EditGoalMovementSheet.show(
      context,
      movement: movement,
      goalName: goalName,
      currency: currency,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    GoalMovementDetailState state,
  ) async {
    final l10n = AppLocalizations.of(context);
    final copy = GoalMovementDeleteCopy.build(
      l10n,
      movement: movement,
      currency: currency,
      goalName: goalName,
      goalCompleted: goalCompleted,
      accounts: state.accounts,
    );
    final confirmed = await ConfirmDeleteGoalMovementSheet.show(
      context,
      title: copy.title,
      message: copy.message,
    );
    if (!(confirmed ?? false) || !context.mounted) {
      return;
    }
    final cubit = context.read<GoalMovementDetailCubit>();
    final result = await cubit.delete(movement);
    if (!context.mounted) {
      return;
    }
    result.fold((_) {}, (_) => Navigator.of(context).pop(true));
  }
}

/// The "Detalles" card of the movement detail sheet: "Fecha" always,
/// "Cuenta de origen"/"Transferencia" only for a money-moving movement whose
/// [accounts] resolved, and "Nota" when present.
class GoalMovementDetailsCard extends StatelessWidget {
  const GoalMovementDetailsCard(
      {required this.movement, this.accounts, super.key});

  final GoalContribution movement;
  final GoalMovementAccounts? accounts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final resolvedAccounts = accounts;
    final note = movement.note;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GoalMovementDetailRow(
            icon: LucideIcons.calendar,
            label: l10n.goalMovementDetailDateLabel,
            value: GoalFormat.dateFull(context, movement.date),
            showTopBorder: false,
          ),
          if (movement.movedMoney && resolvedAccounts != null) ...[
            GoalMovementDetailRow(
              icon: LucideIcons.wallet,
              label: l10n.goalMovementDetailOriginAccountLabel,
              value: resolvedAccounts.originName,
            ),
            GoalMovementDetailRow(
              icon: LucideIcons.arrowLeftRight,
              label: l10n.goalMovementDetailTransferLabel,
              value: l10n.goalMovementDetailTransferValue(
                resolvedAccounts.originName,
                resolvedAccounts.destinationName,
              ),
            ),
          ],
          if (note != null && note.isNotEmpty)
            GoalMovementDetailRow(
              icon: LucideIcons.notebookPen,
              label: l10n.goalMovementDetailNoteLabel,
              value: note,
            ),
        ],
      ),
    );
  }
}

/// One row of the movement detail card: icon, label/value column, with a top
/// divider on every row but the first (`N8Dv2e`'s `strokeWidth: {top: 1}`
/// pattern).
class GoalMovementDetailRow extends StatelessWidget {
  const GoalMovementDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showTopBorder = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: showTopBorder
            ? Border(top: BorderSide(color: colors.border))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
