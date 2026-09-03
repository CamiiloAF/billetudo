import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_message.dart';
import 'ai_message_copy_menu.dart';
import 'ai_orb.dart';
import 'ai_proposal_card.dart';
import 'sheets/ai_report_sheet.dart';

/// One assistant turn (`billetudo.pen` `Io9i3`/`Yuoig`): the orb avatar next
/// to a `$surface` bubble, followed by an `AiProposalCard` per proposal the
/// model attached — `message.proposals` is empty for a plain answer.
class AiAssistantBubble extends StatelessWidget {
  const AiAssistantBubble({
    required this.message,
    required this.accountNames,
    required this.debtNames,
    this.conversationId,
    super.key,
  });

  final AiMessage message;
  final Map<String, String> accountNames;
  final Map<String, String> debtNames;

  /// Groups a filed report with the thread it came from, without carrying the
  /// thread itself (`AiReport`'s own doc). `null` only while a brand-new
  /// conversation has not resolved its id yet — the long-press menu is not
  /// reachable before the first message renders, so this is never actually
  /// null at the point "Reportar" is tappable.
  final String? conversationId;

  Future<void> _report(BuildContext context) async {
    final submitted = await AiReportSheet.show(
      context,
      reportedText: message.content,
      conversationId: conversationId,
    );
    if (submitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).aiReportSuccessMessage),
        ),
      );
    }
  }

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
                onReport: () => unawaited(_report(context)),
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
                  accountNames: accountNames,
                  debtNames: debtNames,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
