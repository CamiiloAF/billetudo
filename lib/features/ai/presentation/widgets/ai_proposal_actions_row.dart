import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_action_proposal.dart';
import '../cubit/ai_action_cubit.dart';

/// An `AiProposalCard`'s Actions Row: two buttons while pending, a disabled
/// pair while dismissed, a read-only confirmation row while confirmed, and a
/// full-width "Reintentar" while failed (`billetudo.pen`
/// `PMCvY`/`gu1wc`/`Dl7UY`).
class AiProposalActionsRow extends StatelessWidget {
  const AiProposalActionsRow({
    required this.messageId,
    required this.proposal,
    required this.busy,
    super.key,
  });

  final String messageId;
  final AiActionProposal proposal;

  /// True while this exact card's write is in flight
  /// (`AiActionState.isPending`).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AiActionCubit>();
    // `UnsupportedProposal` never offers a confirm button
    // (`ai_action_proposal_mapper.dart`'s own contract).
    final canAct = proposal is! UnsupportedProposal;

    switch (proposal.status) {
      case AiProposalStatus.confirmed:
        return Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.checkCircle2,
                  size: 16, color: colors.incomeText),
              const SizedBox(width: 8),
              Text(
                l10n.aiProposalConfirmedRow,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.incomeText,
                ),
              ),
            ],
          ),
        );
      case AiProposalStatus.failed:
        return FilledButton.icon(
          onPressed: !canAct || busy
              ? null
              : () => cubit.confirm(messageId: messageId, proposal: proposal),
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.refreshCw, size: 18),
          label: Text(l10n.aiProposalActionRetry),
        );
      case AiProposalStatus.pending:
      case AiProposalStatus.dismissed:
        final enabled = canAct && proposal.status == AiProposalStatus.pending;
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: enabled && !busy
                    ? () =>
                        cubit.dismiss(messageId: messageId, proposal: proposal)
                    : null,
                child: Text(l10n.aiProposalActionDiscard),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: enabled && !busy
                    ? () =>
                        cubit.confirm(messageId: messageId, proposal: proposal)
                    : null,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.check, size: 18),
                label: Text(l10n.aiProposalActionConfirm),
              ),
            ),
          ],
        );
    }
  }
}
