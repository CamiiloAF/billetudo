import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/privacy_note_strip.dart';

/// No catalogued app is installed on this phone, so there is nothing to
/// switch on (HU-02).
///
/// **Not in `billetudo.pen`** — the zone has the catalog with issuers
/// (`qrDFE`) and the catalog with all of them off (`xqdHH`), but no frame for
/// this one. Flagged for the designer rather than invented as a new visual
/// language: it reuses the shared `Empty State` (`jmQO5`) with the same
/// treatment the other capture empty states use.
///
/// **It must not read as a failure.** No alert iconography, nothing from the
/// `$expense` family, and no call to action — there is no button that would
/// install a bank the user does not have. It states a fact about the phone
/// and names what the catalog covers, so "nothing here" is explained rather
/// than left looking broken.
///
/// The scope note stays on top: this screen is still where the user is told
/// what would be read, even when the answer today is "nothing".
class IssuersNoAppsView extends StatelessWidget {
  const IssuersNoAppsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: <Widget>[
        PrivacyNoteStrip(text: l10n.captureIssuersScopeNote),
        const SizedBox(height: 32),
        EmptyState(
          icon: LucideIcons.smartphone,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          message: l10n.captureIssuersNoAppsTitle,
          description: l10n.captureIssuersNoAppsDescription,
        ),
      ],
    );
  }
}
