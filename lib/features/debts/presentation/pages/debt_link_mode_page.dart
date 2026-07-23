import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../transactions/presentation/pages/transactions_page.dart';
import '../../../transactions/presentation/widgets/transactions_link_mode.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_cash_event.dart';
import '../../domain/services/debt_event_rules.dart';
import '../cubit/debt_link_cubit.dart';

/// Renders Movimientos in link mode (`g0x859`, HU-02) by reusing the existing
/// [TransactionsPage] with a [TransactionsLinkMode] — never a copy of the
/// screen. A row tap links the movement to [debt] through [DebtLinkCubit] and
/// pops back to the debt; the header back button just pops.
class DebtLinkModePage extends StatelessWidget {
  const DebtLinkModePage({required this.debt, super.key});

  final Debt debt;

  @override
  Widget build(BuildContext context) {
    return TransactionsPage(
      // The FAB is hidden and the row/account taps below are unused in link
      // mode, so these are inert stubs.
      onAddTransaction: (_) {},
      onOpenTransaction: (_) async => null,
      onOpenAccount: (_) {},
      linkMode: TransactionsLinkMode(
        // Just the name: the direction ("· Yo debo") confuses more than it
        // helps while picking a movement to attribute.
        debtLabel: debt.name,
        onCancel: () => Navigator.of(context).pop(),
        onLinkTransaction: (transactionId) =>
            _link(context, transactionId),
        // Only the movements that can be an abono of this debt are linkable:
        // "Yo debo" → gastos, "Me deben" → ingresos (HU-02), and never one
        // dated before the debt existed.
        requiredType: DebtEventRules.cashEventType(
          direction: debt.direction,
          kind: DebtCashEventKind.payment,
        ),
        notBefore: debt.createdAt,
      ),
    );
  }

  Future<void> _link(BuildContext context, String transactionId) async {
    final linked =
        await context.read<DebtLinkCubit>().link(transactionId);
    if (!context.mounted) {
      return;
    }
    if (linked) {
      // The debt detail behind updates on its own stream once the movement
      // carries the debt id, so returning there is the whole feedback.
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).debtLinkError)),
        );
    }
  }
}
