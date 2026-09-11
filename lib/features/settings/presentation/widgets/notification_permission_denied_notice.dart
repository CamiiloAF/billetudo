import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neutral_button.dart';

/// The "Tu teléfono tiene las notificaciones apagadas" strip of the
/// Notificaciones screen (`D3gzd` in `VkWqs`).
///
/// It names a state of the **system**, not of the app: with the permission
/// revoked nothing arrives no matter how many switches below are on. Leaving
/// that unexplained is the failure mode that costs this feature the most
/// trust — the app looks like it is lying.
///
/// No border: presence comes from the `$amber-soft` fill alone, the same
/// pattern as the attention states of `Sync Hero`. The CTA is
/// [NeutralButton] and not the primary one because the brand violet fights
/// the amber background (MASTER).
///
/// Tone is informative, never an error and never a reproach: the app names
/// the cause and offers the way out.
class NotificationPermissionDeniedNotice extends StatelessWidget {
  const NotificationPermissionDeniedNotice({
    required this.onOpenSystemSettings,
    super.key,
  });

  final VoidCallback onOpenSystemSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.amberSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.bellOff,
                size: 18,
                color: colors.amberText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.notificationsPermissionDeniedTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.notificationsPermissionDeniedBody,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          NeutralButton(
            label: l10n.notificationsPermissionDeniedCta,
            icon: LucideIcons.externalLink,
            onPressed: onOpenSystemSettings,
          ),
        ],
      ),
    );
  }
}
