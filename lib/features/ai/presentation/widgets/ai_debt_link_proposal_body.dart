import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_action_proposal.dart';
import 'ai_proposal_detail_row.dart';

/// The Body Slot for a `link_transaction_to_debt` proposal: the debt the
/// movement will be attributed to, plus the one thing this card has to say out
/// loud.
///
/// Unlike every other proposal, this one creates nothing and moves no money —
/// the movement already hit its account. Reading "confirmar" here and expecting
/// a second charge is the most likely misreading of the whole feature, so the
/// explainer is part of the body, not a footnote the eye skips.
class AiDebtLinkProposalBody extends StatelessWidget {
  const AiDebtLinkProposalBody({
    required this.proposal,
    required this.debtNames,
    super.key,
  });

  final LinkTransactionToDebtProposal proposal;

  /// `Debt.id` → `Debt.name`, from `AiChatState.debtNames`. A debt the device
  /// cannot resolve falls back to a generic label; the raw id is never shown.
  final Map<String, String> debtNames;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AiProposalDetailRow(
          label: l10n.aiProposalTransactionDebt,
          value: debtNames[proposal.debtId] ?? l10n.aiProposalDebtUnknown,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.aiProposalDebtLinkExplainer,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
