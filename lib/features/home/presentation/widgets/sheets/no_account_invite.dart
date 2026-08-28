import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../account_avatar.dart';

/// `AccountSheet`'s "sin cuenta" variant: an "Activar respaldo" invite in
/// place of the settings/sign-out rows.
class NoAccountInvite extends StatelessWidget {
  const NoAccountInvite({required this.onActivateBackup, super.key});

  final VoidCallback onActivateBackup;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AccountAvatar(badge: AccountAvatarBadge.noAccount),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.homeAccountSheetNoAccountTitle,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    l10n.homeAccountSheetNoAccountBody,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onActivateBackup,
            child: Text(l10n.homeAccountSheetActivateBackup),
          ),
        ),
      ],
    );
  }
}
