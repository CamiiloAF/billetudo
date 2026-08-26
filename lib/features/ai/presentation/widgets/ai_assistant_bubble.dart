import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_message.dart';
import 'ai_message_copy_menu.dart';
import 'ai_orb.dart';
import 'ai_proposal_card.dart';

/// One assistant turn (`billetudo.pen` `Io9i3`/`Yuoig`): the orb avatar next
/// to a `$surface` bubble, followed by an `AiProposalCard` per proposal the
/// model attached — `message.proposals` is empty for a plain answer.
class AiAssistantBubble extends StatelessWidget {
  const AiAssistantBubble({
    required this.message,
    required this.accountNames,
    super.key,
  });

  final AiMessage message;
  final Map<String, String> accountNames;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AiOrb(),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AiMessageCopyMenu(
                textToCopy: message.content,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              for (final proposal in message.proposals) ...[
                const SizedBox(height: 10),
                AiProposalCard(
                    messageId: message.id,
                    proposal: proposal,
                    accountNames: accountNames),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
