import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The fixed strip `AiConversationReadPage` shows under its header, same
/// fixed-under-header slot as `AiBetaStrip` on the real chat screen: explains
/// why the composer is missing and offers a direct way back to
/// `AiConsentPage` to reactivate the assistant.
///
/// No `billetudo.pen` frame exists for this screen (same gap as
/// `AiConsentPage`'s own doc comment) — it borrows `AiBetaStrip`'s shape
/// (fixed `$muted` strip, not part of the scrollable conversation) rather
/// than inventing a new one-off.
class AiReadOnlyBanner extends StatelessWidget {
  const AiReadOnlyBanner({required this.onReactivate, super.key});

  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      color: colors.muted,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.eye, size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.aiConversationReadBannerMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onReactivate,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.aiConversationReadReactivateCta,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
