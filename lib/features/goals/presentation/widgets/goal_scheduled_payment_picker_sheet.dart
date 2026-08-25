import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../scheduled_payments/presentation/widgets/scheduled_card.dart';
import '../cubit/goal_recurring_contribution_cubit.dart';
import '../cubit/goal_recurring_contribution_state.dart';

/// HU-16 "Enlazar existente" picker (`RX8C9`/`LSwr8`): lists the templates
/// eligible to be linked (active, without a `debtId`/`goalId` yet) via
/// `ScheduledCard` — the same row `pagos-programados` already uses — so
/// selecting one attributes it to the goal instead of duplicating it.
class GoalScheduledPaymentPickerSheet extends StatelessWidget {
  const GoalScheduledPaymentPickerSheet({super.key});

  /// Opens the picker and resolves to `true` once a payment was successfully
  /// linked, or `null`/`false` if dismissed/failed.
  static Future<bool?> show(
    BuildContext context, {
    required String goalId,
    required String goalName,
    required String currency,
  }) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) => BlocProvider(
          create: (context) {
            final cubit = getIt<GoalRecurringContributionCubit>();
            unawaited(
              cubit
                  .start(goalId: goalId, goalName: goalName, currency: currency)
                  .then((_) => cubit.watchLinkablePayments()),
            );
            return cubit;
          },
          child: const GoalScheduledPaymentPickerSheet(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoalRecurringContributionCubit,
        GoalRecurringContributionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == GoalRecurringContributionStatus.saved) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) =>
          GoalScheduledPaymentPickerSheetBody(state: state),
    );
  }
}

class GoalScheduledPaymentPickerSheetBody extends StatelessWidget {
  const GoalScheduledPaymentPickerSheetBody({required this.state, super.key});

  final GoalRecurringContributionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final cubit = context.read<GoalRecurringContributionCubit>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetMessage(
          icon: LucideIcons.calendarClock,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: l10n.goalRecurringContributionPickerTitle,
          message: l10n.goalRecurringContributionPickerSubtitle,
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.linkablePayments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      l10n.goalRecurringContributionPickerEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  )
                else
                  for (final entry in state.linkablePayments) ...[
                    ScheduledCard(
                      entry: entry,
                      onTap: () =>
                          cubit.linkExisting(entry.scheduledPayment.id),
                    ),
                    const SizedBox(height: 10),
                  ],
                if (state.failure != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.goalRecurringContributionLinkError,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.expenseText),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
