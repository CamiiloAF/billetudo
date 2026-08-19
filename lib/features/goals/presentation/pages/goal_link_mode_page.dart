import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../transactions/presentation/pages/transactions_page.dart';
import '../../../transactions/presentation/widgets/transactions_link_mode.dart';
import '../../../tutorials/domain/entities/tutorial_key.dart';
import '../../../tutorials/presentation/widgets/tutorial_auto_show.dart';
import '../../domain/entities/goal_contribution.dart';
import '../cubit/goal_link_cubit.dart';

/// Renders Movimientos in link mode (HU-03 "Enlazar un movimiento") by
/// reusing the existing [TransactionsPage] with a [TransactionsLinkMode] —
/// never a copy of the screen, same precedent as `DebtLinkModePage`. A row
/// tap links the movement to the goal through [GoalLinkCubit] and pops back;
/// the header back button just pops.
class GoalLinkModePage extends StatelessWidget {
  const GoalLinkModePage({
    required this.goalId,
    required this.goalName,
    required this.direction,
    super.key,
  });

  final String goalId;
  final String goalName;
  final GoalMovementDirection direction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TutorialAutoShow(
      tutorialKey: TutorialKey.goalLinkMovement,
      child: TransactionsPage(
        // The FAB is hidden and the row/account taps below are unused in link
        // mode, so these are inert stubs.
        onAddTransaction: (_) {},
        onOpenTransaction: (_) async => null,
        onOpenAccount: (_) {},
        linkMode: TransactionsLinkMode(
          bannerTitle: l10n.goalLinkBannerTitle(goalName),
          bannerBody: l10n.goalLinkBannerBody,
          onCancel: () => Navigator.of(context).pop(),
          onLinkTransaction: (transactionId) => _link(context, transactionId),
          // Any movement type is eligible (HU-03): unlike a debt's abono, a
          // goal movement carries no cash-direction constraint.
        ),
      ),
    );
  }

  Future<void> _link(BuildContext context, String transactionId) async {
    final linked = await context.read<GoalLinkCubit>().link(transactionId);
    if (!context.mounted) {
      return;
    }
    if (linked) {
      // The goal detail behind updates on its own stream once the movement
      // carries the goal's contribution row, so returning there is the whole
      // feedback.
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          AppSnackBar(content: Text(AppLocalizations.of(context).goalLinkError)),
        );
    }
  }
}
