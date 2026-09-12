import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/ai_action_proposal.dart';
import 'ai_proposal_detail_row.dart';
import 'ai_proposal_divider.dart';

/// The Body Slot for a `create_category` proposal: income/expense and
/// whether it is a subcategory.
class AiCategoryProposalBody extends StatelessWidget {
  const AiCategoryProposalBody({required this.proposal, super.key});

  final CreateCategoryProposal proposal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AiProposalDetailRow(
          label: l10n.aiProposalCategoryType,
          value: proposal.kind == CategoryKind.income
              ? l10n.categoryKindIncome
              : l10n.categoryKindExpense,
        ),
        const AiProposalDivider(),
        AiProposalDetailRow(
          label: l10n.aiProposalCategoryScope,
          value: proposal.parentId == null
              ? l10n.aiProposalCategoryScopeRoot
              : l10n.aiProposalCategoryScopeSub,
        ),
      ],
    );
  }
}
