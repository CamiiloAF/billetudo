import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'ai_orb.dart';

/// The "no pude responder" bubble (`billetudo.pen` `V7gvu`/`oNEVR`): the same
/// bubble chrome as a normal reply, with an `$expense-text` header and a
/// "Reintentar" link — never a destructive-red retry, this is a network
/// hiccup, not an alarm.
class AiErrorBubble extends StatelessWidget {
  const AiErrorBubble({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AiOrb(),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.triangleAlert,
                      size: 16,
                      color: colors.expenseText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.aiChatErrorTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.expenseText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.aiChatErrorBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onRetry,
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.refreshCw,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.commonRetry,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
