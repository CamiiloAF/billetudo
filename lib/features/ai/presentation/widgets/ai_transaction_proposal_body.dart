import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/ai_action_proposal.dart';
import 'ai_proposal_detail_row.dart';
import 'ai_proposal_divider.dart';

/// The Body Slot for a `create_transaction` proposal: amount, type, date,
/// account and — when the movement is born attributed to a debt — the debt it
/// will count against. Both ids are resolved to names via
/// `AiChatState.accountNames`/`debtNames`.
///
/// The debt row is not optional chrome: confirming an attribution the card
/// never showed is exactly what makes a proposal untrustworthy, so when
/// `proposal.debtId` is set the row is rendered even if the name cannot be
/// resolved (a generic label then stands in, never the raw id).
class AiTransactionProposalBody extends StatelessWidget {
  const AiTransactionProposalBody({
    required this.proposal,
    required this.accountNames,
    required this.debtNames,
    super.key,
  });

  final CreateTransactionProposal proposal;
  final Map<String, String> accountNames;
  final Map<String, String> debtNames;

  static const MoneyFormatter _money = MoneyFormatter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AiProposalDetailRow(
          label: l10n.aiProposalAmount,
          value: _money.formatSymbol(
            proposal.amountMinor,
            currencyCode: proposal.currency,
          ),
        ),
        const AiProposalDivider(),
        AiProposalDetailRow(
          label: l10n.aiProposalTransactionType,
          value: proposal.type == TransactionType.income
              ? l10n.transactionTypeIncome
              : l10n.transactionTypeExpense,
        ),
        const AiProposalDivider(),
        AiProposalDetailRow(
          label: l10n.aiProposalTransactionDate,
          value: DateFormat('d MMM y', locale).format(proposal.date),
        ),
        const AiProposalDivider(),
        AiProposalDetailRow(
          label: l10n.aiProposalTransactionAccount,
          value: accountNames[proposal.accountId] ??
              l10n.aiProposalTransactionAccountUnknown,
        ),
        if (proposal.debtId case final String debtId) ...[
          const AiProposalDivider(),
          AiProposalDetailRow(
            label: l10n.aiProposalTransactionDebt,
            value: debtNames[debtId] ?? l10n.aiProposalDebtUnknown,
          ),
        ],
      ],
    );
  }
}
