import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/ai_action_proposal.dart';
import 'ai_proposal_detail_row.dart';
import 'ai_proposal_divider.dart';

/// The Body Slot for a `create_goal` proposal: target amount and, when set, a
/// target date.
class AiGoalProposalBody extends StatelessWidget {
  const AiGoalProposalBody({required this.proposal, super.key});

  final CreateGoalProposal proposal;

  static const MoneyFormatter _money = MoneyFormatter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final targetDate = proposal.targetDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AiProposalDetailRow(
          label: l10n.aiProposalGoalTarget,
          value: _money.formatSymbol(
            proposal.targetMinor,
            currencyCode: proposal.currency,
          ),
        ),
        const AiProposalDivider(),
        AiProposalDetailRow(
          label: l10n.aiProposalGoalDate,
          value: targetDate == null
              ? l10n.aiProposalGoalNoDate
              : DateFormat('d MMM y', locale).format(targetDate),
        ),
      ],
    );
  }
}
