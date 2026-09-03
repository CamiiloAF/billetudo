import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_header_circle_button.dart';

/// The chat screen's header (`billetudo.pen` `fKVDX`, a per-instance override
/// of `Dtm0X`): `Left Group` is the back button plus an invisible 44x44
/// spacer so the title stays centered against the heavier `Right Group`
/// (history + nueva conversación), same pattern as `Home Header`/Deudas'
/// header. The base `Page Header` component itself is untouched — only this
/// screen composes two action groups.
class AiChatHeader extends StatelessWidget {
  const AiChatHeader({
    required this.onBack,
    required this.onOpenHistory,
    required this.onNewConversation,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onOpenHistory;
  final VoidCallback onNewConversation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          PageHeaderCircleButton(
            icon: LucideIcons.arrowLeft,
            background: colors.muted,
            foreground: colors.textPrimary,
            tooltip: l10n.commonBack,
            onPressed: onBack,
          ),
          const SizedBox(width: 44),
          Expanded(
            child: Text(
              l10n.aiChatTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          PageHeaderCircleButton(
            icon: LucideIcons.history,
            background: colors.muted,
            foreground: colors.textPrimary,
            tooltip: l10n.aiChatHistoryTooltip,
            iconSize: 20,
            onPressed: onOpenHistory,
          ),
          const SizedBox(width: 8),
          PageHeaderCircleButton(
            icon: LucideIcons.plus,
            background: colors.primary,
            foreground: colors.onPrimary,
            tooltip: l10n.aiChatNewConversationTooltip,
            onPressed: onNewConversation,
          ),
        ],
      ),
    );
  }
}
