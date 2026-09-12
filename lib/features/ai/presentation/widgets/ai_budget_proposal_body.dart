import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../budgets/presentation/utils/budget_format.dart';
import '../../domain/entities/ai_action_proposal.dart';
import 'ai_proposal_detail_row.dart';
import 'ai_proposal_divider.dart';

/// The Body Slot for a `create_budget` proposal (`billetudo.pen`
/// `aWTcH`/`TmIac`): amount, period and category scope.
///
/// Category/account ids never resolve to a name here — [CreateBudgetProposal]
/// only carries ids, and this widget has no read wired to look them up (see
/// `AiChatState.accountNames`'s doc). The scope reads as a plain count
/// instead, which is honest rather than a fabricated label.
class AiBudgetProposalBody extends StatelessWidget {
  const AiBudgetProposalBody({required this.proposal, super.key});

  final CreateBudgetProposal proposal;

  static const MoneyFormatter _money = MoneyFormatter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
          label: l10n.aiProposalPeriod,
          value: BudgetFormat.periodLabel(l10n, proposal.period),
        ),
        const AiProposalDivider(),
        AiProposalDetailRow(
          label: l10n.aiProposalCategory,
          value: proposal.categoryIds.isEmpty
              ? l10n.aiProposalScopeAllCategories
              : l10n.aiProposalScopeSomeCategories(proposal.categoryIds.length),
        ),
      ],
    );
  }
}
