import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/privacy_note_strip.dart';
import 'permission_fact_row.dart';

/// `Permission Explainer Body` (`H6JaA`, `reusable:true`): the body of the
/// screen the user sees **before** the app sends them out to Android's
/// settings (HU-01).
///
/// The four facts are not decoration: they are the four things HU-01 requires
/// this screen to say — what is read, what is stored, that nothing is
/// recorded without confirmation, and what syncs. The strip at the bottom
/// pre-empts the system's own warning, so the user meets it having been told
/// it was coming instead of being ambushed by it.
///
/// The title describes and does not promise ("Leer los avisos de tu banco",
/// never "tus gastos se registran solos"): the app cannot capture cash, cannot
/// capture banks outside the catalog, and the system can kill the service.
///
/// The CTAs are **not** here — the screen anchors them at the bottom.
class PermissionExplainerBody extends StatelessWidget {
  const PermissionExplainerBody({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            LucideIcons.bellRing,
            size: 30,
            color: colors.primaryOnSoft,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.capturePermissionTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.capturePermissionBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        PermissionFactRow(
          icon: LucideIcons.eye,
          title: l10n.capturePermissionFactAppsTitle,
          description: l10n.capturePermissionFactAppsDescription,
        ),
        const SizedBox(height: 14),
        PermissionFactRow(
          icon: LucideIcons.shieldCheck,
          title: l10n.capturePermissionFactDataTitle,
          description: l10n.capturePermissionFactDataDescription,
        ),
        const SizedBox(height: 14),
        PermissionFactRow(
          icon: LucideIcons.checkCheck,
          title: l10n.capturePermissionFactConfirmTitle,
          description: l10n.capturePermissionFactConfirmDescription,
        ),
        const SizedBox(height: 14),
        PermissionFactRow(
          icon: LucideIcons.cloud,
          title: l10n.capturePermissionFactSyncTitle,
          description: l10n.capturePermissionFactSyncDescription,
        ),
        const SizedBox(height: 14),
        PrivacyNoteStrip(
          icon: LucideIcons.info,
          text: l10n.capturePermissionSystemWarning,
        ),
      ],
    );
  }
}
