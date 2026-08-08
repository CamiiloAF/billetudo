import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/date_picker_sheet.dart';
import '../../../../../core/widgets/note_autocomplete_field.dart';
import '../../../domain/entities/goal_contribution.dart';
import '../../cubit/edit_goal_movement_cubit.dart';
import '../../cubit/edit_goal_movement_state.dart';
import '../../utils/goal_format.dart';
import '../currency_pill.dart';
import '../goal_amount_hero_field.dart';
import '../goal_movement_field_label.dart';
import '../goal_movement_selector_box.dart';

/// "Editar movimiento" (`goal_movement_detail_sheet.dart`'s Editar for a
/// tracking-only [GoalContribution], `transactionId == null`): lets the user
/// correct monto/fecha/nota of that SAME row — never creates or deletes a
/// movement, unlike `GoalContributionSheet`. A money-moving movement never
/// reaches this sheet; it opens the linked transaction instead.
///
/// Resolves to `true` once the edit was actually saved, or `null` when the
/// sheet was dismissed without saving.
class EditGoalMovementSheet extends StatelessWidget {
  const EditGoalMovementSheet({super.key});

  static Future<bool?> show(
    BuildContext context, {
    required GoalContribution movement,
    required String goalName,
    required String currency,
  }) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) => BlocProvider(
          create: (context) => getIt<EditGoalMovementCubit>()
            ..start(movement, goalName: goalName, currency: currency),
          child: const EditGoalMovementSheet(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditGoalMovementCubit, EditGoalMovementState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == EditGoalMovementStatus.saved) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) => EditGoalMovementSheetBody(state: state),
    );
  }
}

class EditGoalMovementSheetBody extends StatelessWidget {
  const EditGoalMovementSheetBody({required this.state, super.key});

  final EditGoalMovementState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final cubit = context.read<EditGoalMovementCubit>();

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
                  l10n.goalMovementEditTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.goalMovementEditHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                GoalMovementFieldLabel(text: l10n.goalMovementAmountLabel),
                const SizedBox(height: 6),
                GoalAmountHeroField(
                  fieldKey: const ValueKey('edit-goal-movement-amount'),
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
                  // Only a retiro can reach this failure in practice — a
                  // monto <= 0 already keeps `canSubmit` false, so submit()
                  // never runs — but the withdraw-specific copy would be
                  // wrong for an aporte, so it falls back to the generic,
                  // still field-anchored message in that case.
                  errorText: state.isAmountFailure
                      ? (state.isWithdrawal
                          ? l10n.goalWithdrawErrorExceedsSaved
                          : l10n.goalMovementError)
                      : null,
                ),
                const SizedBox(height: 14),
                GoalMovementFieldLabel(text: l10n.goalMovementDateLabel),
                const SizedBox(height: 6),
                GoalMovementSelectorBox(
                  icon: LucideIcons.calendar,
                  value: GoalFormat.relativeDate(context, l10n, state.date),
                  onTap: () => unawaited(_pickDate(context, cubit, state.date)),
                  trailingIcon: LucideIcons.chevronRight,
                ),
                const SizedBox(height: 14),
                GoalMovementFieldLabel(text: l10n.goalMovementNoteLabel),
                const SizedBox(height: 6),
                NoteAutocompleteField(
                  key: const ValueKey('edit-goal-movement-note'),
                  initialValue: state.note,
                  hint: l10n.goalMovementNoteHint,
                  onChanged: cubit.noteChanged,
                ),
                if (state.failure != null && !state.isAmountFailure) ...[
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
            key: const ValueKey('edit-goal-movement-submit'),
            onPressed: state.canSubmit ? cubit.submit : null,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.commonSave),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    EditGoalMovementCubit cubit,
    DateTime current,
  ) async {
    final picked = await DatePickerSheet.show(
      context,
      initialDate: current,
      disabledAfter: clock.now(),
    );
    if (picked != null) {
      cubit.dateChanged(picked);
    }
  }
}
