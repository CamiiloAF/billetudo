import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_action_proposal.dart';
import '../cubit/ai_action_cubit.dart';
import '../cubit/ai_action_state.dart';
import 'ai_budget_proposal_body.dart';
import 'ai_category_proposal_body.dart';
import 'ai_debt_link_proposal_body.dart';
import 'ai_goal_proposal_body.dart';
import 'ai_proposal_actions_row.dart';
import 'ai_proposal_card_kicker.dart';
import 'ai_transaction_proposal_body.dart';
import 'ai_unsupported_proposal_body.dart';

/// `AI Proposal Card` (`billetudo.pen` `TmIac`): the one place a suggestion
/// can become a real write, and only on an explicit "Confirmar" tap.
///
/// Chrome (kicker, title, footnote, actions) is fixed; the Body Slot swaps
/// per [proposal] kind via the exhaustive switch below — the same component
/// renders a budget, a goal, a category or a transaction proposal without
/// ever restructuring itself, matching `asistente-ia.md`'s "Body Slot"
/// contract.
class AiProposalCard extends StatelessWidget {
  const AiProposalCard({
    required this.messageId,
    required this.proposal,
    required this.accountNames,
    required this.debtNames,
    super.key,
  });

  final String messageId;
  final AiActionProposal proposal;
  final Map<String, String> accountNames;

  /// `Debt.id` → `Debt.name`, so a proposal that attributes a movement to a
  /// debt can name it instead of asking the user to trust a bare id.
  final Map<String, String> debtNames;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<AiActionCubit, AiActionState>(
      builder: (context, actionState) {
        final busy = actionState.isPending(proposal.id);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Opacity(
            // The dismissed state dims to 94% — the measured floor that still
            // clears WCAG AA against `$surface` (`asistente-ia.md`). Every
            // other status stays fully opaque.
            opacity: proposal.status == AiProposalStatus.dismissed ? 0.94 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AiProposalCardKicker(status: proposal.status),
                const SizedBox(height: 12),
                Text(
                  proposal.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                switch (proposal) {
                  final CreateBudgetProposal p =>
                    AiBudgetProposalBody(proposal: p),
                  final CreateGoalProposal p => AiGoalProposalBody(proposal: p),
                  final CreateCategoryProposal p =>
                    AiCategoryProposalBody(proposal: p),
                  final CreateTransactionProposal p =>
                    AiTransactionProposalBody(
                      proposal: p,
                      accountNames: accountNames,
                      debtNames: debtNames,
                    ),
                  final LinkTransactionToDebtProposal p =>
                    AiDebtLinkProposalBody(
                      proposal: p,
                      debtNames: debtNames,
                    ),
                  UnsupportedProposal() => const AiUnsupportedProposalBody(),
                },
                const SizedBox(height: 10),
                Text(
                  _footnote(l10n, proposal),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                AiProposalActionsRow(
                  messageId: messageId,
                  proposal: proposal,
                  busy: busy,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _footnote(AppLocalizations l10n, AiActionProposal proposal) =>
      switch (proposal.status) {
        AiProposalStatus.pending => l10n.aiProposalFootnotePending,
        AiProposalStatus.confirmed => _confirmedFootnote(l10n, proposal),
        AiProposalStatus.dismissed => l10n.aiProposalFootnoteDismissed,
        AiProposalStatus.failed => l10n.aiProposalFootnoteFailed,
      };

  /// Matches the exhaustive body-slot switch above: a confirmed proposal's
  /// footnote names the entity it just created, never a generic
  /// "transactions" copy for a budget/goal/category.
  String _confirmedFootnote(AppLocalizations l10n, AiActionProposal proposal) =>
      switch (proposal) {
        CreateBudgetProposal() => l10n.aiProposalFootnoteConfirmedBudget,
        CreateGoalProposal() => l10n.aiProposalFootnoteConfirmedGoal,
        CreateCategoryProposal() => l10n.aiProposalFootnoteConfirmedCategory,
        CreateTransactionProposal() =>
          l10n.aiProposalFootnoteConfirmedTransaction,
        LinkTransactionToDebtProposal() =>
          l10n.aiProposalFootnoteConfirmedDebtLink,
        UnsupportedProposal() => l10n.aiProposalFootnoteConfirmedTransaction,
      };
}
