import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The legal notice fixed under the chat header (`billetudo.pen` `RGcg1`):
/// a "Beta" badge plus the AI-generated-content disclaimer. Not dismissible
/// and never inside the scrollable conversation — `asistente-ia.md` calls it
/// a legal requirement, not decoration.
class AiBetaStrip extends StatelessWidget {
  const AiBetaStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      color: colors.muted,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.aiChatBetaBadge,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.aiChatDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colors.segmentInactiveText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
