import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_conversation.dart';
import '../utils/ai_format.dart';

/// One thread of the history list (`billetudo.pen` `cBizM`): title + relative
/// date, then a full-width borrable footer.
///
/// The footer's tap target is the whole row, not just the icon+label — it
/// measures 44pt tall but its content hugs the right edge
/// (`justifyContent:"end"`), the same "tappable beyond the visible glyph"
/// rule `Delete Opt-in Row` already follows (`asistente-ia.md`, "Pendientes").
class ConversationRow extends StatelessWidget {
  const ConversationRow({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final AiConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final title = conversation.title ?? l10n.aiHistoryRowUntitled;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: colors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: conversation.title == null
                            ? colors.textSecondary
                            : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AiFormat.conversationTimestamp(
                        context,
                        l10n,
                        conversation.updatedAt,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onDelete,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(LucideIcons.trash2,
                        size: 18, color: colors.expenseText),
                    const SizedBox(width: 6),
                    Text(
                      l10n.aiHistoryRowDelete,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.expenseText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
