import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_message.dart';

/// A user's own bubble (`billetudo.pen` `e9agnz`): right-aligned, `$primary`
/// fill, the one corner facing the tail squared off.
///
/// [message].status is never rendered as a visual difference for
/// [AiMessageStatus.sent]/[AiMessageStatus.pending] — the composer already
/// shows the turn is in flight via the chat's own `thinking` state. A
/// [AiMessageStatus.failed] bubble (send lost the network entirely, before
/// any reply) gets a small reassurance note instead: no frame exists for
/// this in `billetudo.pen`, so it follows the same "datos a salvo" tone as
/// the chat's own error bubble rather than inventing new copy.
class AiUserBubble extends StatelessWidget {
  const AiUserBubble({required this.message, super.key});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 262),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: colors.onPrimary,
                ),
              ),
            ),
          ),
          if (message.status == AiMessageStatus.failed) ...[
            const SizedBox(height: 4),
            Text(
              l10n.aiChatMessageFailed,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.expenseText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
