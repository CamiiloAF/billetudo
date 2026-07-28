import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/date_picker_sheet.dart';
import '../../../domain/entities/goal_contribution.dart';
import '../../cubit/goal_contribution_cubit.dart';
import '../../cubit/goal_contribution_state.dart';
import '../../utils/goal_format.dart';
import '../goal_amount_hero_field.dart';
import '../goal_movement_field_label.dart';
import '../goal_movement_selector_box.dart';

/// Registrar aporte/retiro (HU-03/HU-04), tracking-only version (`ZgR6U`
/// Aportar-mover OFF / `jFfBT` Retirar-mover OFF): the amount héroe, an
/// optional note, fecha, and — for a retiro — the hard cap and "Usar todo"
/// chip. The "¿Mover dinero de una cuenta?" toggle has no approved frame yet
/// (tracked as a separate follow-up), so this always writes a pure
/// `GoalContribution` row.
///
/// Resolves to the milestone threshold newly crossed (HU-06), or `null`,
/// once the save settles — the caller decides whether to celebrate.
class GoalContributionSheet extends StatelessWidget {
  const GoalContributionSheet({super.key});

  static Future<int?> show(
    BuildContext context, {
    required String goalId,
    required GoalMovementDirection direction,
    required String currency,
    int maxWithdrawableMinor = 0,
  }) =>
      BottomSheetBase.show<int?>(
        context,
        builder: (context) => BlocProvider(
          create: (context) => getIt<GoalContributionCubit>()
            ..start(
              goalId: goalId,
              direction: direction,
              currency: currency,
              maxWithdrawableMinor: maxWithdrawableMinor,
            ),
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
                      ? l10n.goalWithdrawTitle
                      : l10n.goalContributeTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                GoalAmountHeroField(
                  fieldKey: const ValueKey('goal-amount-movement'),
                  label: state.isWithdrawal
                      ? l10n.goalWithdrawAmountLabel
                      : l10n.goalContributeAmountLabel,
                  currency: state.currency,
                  initialAmountMinor: state.amountMinor,
                  onChanged: cubit.amountChanged,
                  autofocus: true,
                  errorText: state.isWithdrawal &&
                          state.amountMinor > state.maxWithdrawableMinor
                      ? l10n.goalWithdrawErrorExceedsSaved
                      : null,
                ),
                if (state.isWithdrawal) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: cubit.useMax,
                      child: Text(
                        l10n.goalWithdrawAvailable(
                          GoalFormat.amount(
                            state.maxWithdrawableMinor,
                            state.currency,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
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
                TextFormField(
                  key: const ValueKey('goal-movement-note'),
                  initialValue: state.note,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: cubit.noteChanged,
                  decoration: InputDecoration(hintText: l10n.goalMovementNoteHint),
                ),
                if (state.failure != null) ...[
                  const SizedBox(height: 12),
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
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(
              state.isWithdrawal ? l10n.goalWithdrawCta : l10n.goalContributeCta,
            ),
          ),
        ),
      ],
    );
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
}
