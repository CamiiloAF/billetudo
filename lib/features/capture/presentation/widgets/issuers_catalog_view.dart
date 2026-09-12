import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/privacy_note_strip.dart';
import '../../domain/entities/issuer_app.dart';
import '../cubit/capture_issuers_state.dart';
import 'issuer_switch_row.dart';
import 'issuers_summary_row.dart';

/// `qrDFE` / `xqdHH` — the issuer catalog itself (HU-02).
///
/// Only apps that are **both** in the curated catalog and installed on this
/// phone get a row, every one of them off until the user says otherwise. The
/// closing note explains that the catalog is closed without making it sound
/// like the app is broken: there is no "request your bank" form in this
/// release, on purpose.
class IssuersCatalogView extends StatelessWidget {
  const IssuersCatalogView({
    required this.state,
    required this.onIssuerChanged,
    required this.onTurnOffAll,
    super.key,
  });

  final CaptureIssuersState state;
  final void Function(IssuerApp issuer, {required bool enabled})
      onIssuerChanged;
  final VoidCallback onTurnOffAll;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: <Widget>[
        PrivacyNoteStrip(text: l10n.captureIssuersScopeNote),
        const SizedBox(height: 14),
        IssuersSummaryRow(
          enabledCount: state.enabledCount,
          totalCount: state.issuers.length,
          onTurnOffAll: onTurnOffAll,
        ),
        const SizedBox(height: 14),
        for (final IssuerApp issuer in state.issuers) ...<Widget>[
          IssuerSwitchRow(
            issuer: issuer,
            onChanged: (bool enabled) =>
                onIssuerChanged(issuer, enabled: enabled),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        Text(
          l10n.captureIssuersClosedCatalogNote,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
