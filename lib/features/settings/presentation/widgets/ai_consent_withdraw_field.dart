import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// "Retirar el consentimiento de IA" in Ajustes › Asistente de IA — the
/// counterpart of the consent screen, required by RGPD art. 7.3 (withdrawing
/// must be as easy as granting).
///
/// Same card shape as its neighbour `AiNotesAccessField` (icon wrap + label +
/// subtitle) so the section reads as one block, with a chevron instead of a
/// switch: this opens a confirmation sheet rather than flipping a value.
///
/// Neutral, not destructive: `$muted` wrap and secondary-tone icon, never the
/// `$expense` of `Delete Link` (`u0THG`). Nothing is deleted here and the
/// person is not making a mistake — the tone rule of the product applies to
/// permissions too.
class AiConsentWithdrawField extends StatelessWidget {
  const AiConsentWithdrawField({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(AppTheme.radiusLarge);

    return Material(
      color: colors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  LucideIcons.shieldOff,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsAiConsentWithdraw,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    // Unbounded on purpose, like `AiNotesAccessField`'s: the
                    // reassuring half ("puedes volver a activarlo") is the
                    // part truncation would drop.
                    Text(
                      l10n.settingsAiConsentWithdrawSubtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
