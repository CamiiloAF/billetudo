import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/privacy_note_strip.dart';

/// `ZGtoE` — "the reading of your bank's alerts is off" (HU-01/HU-09).
///
/// Shown on returning from Ajustes without granting the permission, and when
/// the user revokes it from the system later.
///
/// **The tone is the requirement here**, not a preference. No alert
/// iconography (no triangles, no `circle-alert`), nothing from the `$expense`
/// family, and no insistence: the icon is `bell-off` on `$muted` and the copy
/// says outright that the rest of the app is unaffected. Someone who declined
/// the most invasive permission on their phone made a legitimate choice, and
/// this screen is not allowed to argue with it.
///
/// It also states that pending captures are **not** deleted (HU-09): turning
/// the feature off must never read as losing work already done.
class CaptureDisabledView extends StatelessWidget {
  const CaptureDisabledView({
    required this.onOpenSettings,
    required this.onSeeHowItWorks,
    super.key,
  });

  /// Back out to `ACTION_NOTIFICATION_LISTENER_SETTINGS`. Available, but not
  /// urgent: it is the last thing on the screen for a reason.
  final VoidCallback onOpenSettings;

  final VoidCallback onSeeHowItWorks;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);

    // `vKPkC` centres its content vertically. `mainAxisAlignment` alone would
    // be inert inside a scroll view (the column sizes to its children), so
    // the viewport height becomes a *minimum*: centred when the content fits,
    // scrollable when a large text scale makes it taller than the screen.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.muted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        LucideIcons.bellOff,
                        size: 22,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.captureDisabledTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.captureDisabledBody,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrivacyNoteStrip(
                icon: LucideIcons.inbox,
                text: l10n.captureDisabledPendingNote,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(LucideIcons.externalLink, size: 18),
                label: Text(l10n.captureDisabledOpenSettingsCta),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onSeeHowItWorks,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(l10n.captureSeeHowItWorksCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
