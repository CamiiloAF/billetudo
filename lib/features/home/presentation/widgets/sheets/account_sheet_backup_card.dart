import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// `AccountSheet`'s "sin cuenta" `Hero Card` (`mMJBH`,
/// `design-system/billetudo/pages/inicio.md` § "Hoja de cuenta"): vertical,
/// centered — icon circle, title/subtitle, primary CTA. Replaces the
/// signed-in `AccountSheetHeroCard` for that variant.
class AccountSheetBackupCard extends StatelessWidget {
  const AccountSheetBackupCard({required this.onActivateBackup, super.key});

  final VoidCallback onActivateBackup;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.cloudUpload,
              size: 26,
              color: colors.primaryOnSoft,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.homeAccountSheetNoAccountTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.homeAccountSheetNoAccountBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onActivateBackup,
              icon: const Icon(LucideIcons.cloudUpload, size: 18),
              label: Text(l10n.homeAccountSheetActivateBackup),
            ),
          ),
        ],
      ),
    );
  }
}
