import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/external_url_opener.dart';
import '../../../../core/widgets/settings_field.dart';

/// A `SettingsField` row that opens a public legal page in the system browser
/// (`lib/core/config/legal_urls.dart`).
///
/// Both stores require the privacy policy and the terms of use to be
/// reachable from inside the app, so a silent failure is not acceptable:
/// when nothing can handle the URL, the row reports it with a snackbar
/// instead of doing nothing.
class LegalLinkField extends StatelessWidget {
  const LegalLinkField({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.url,
    this.openUrl = openExternalUrl,
    super.key,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Uri url;

  /// Injected so widget tests never reach the `url_launcher` platform
  /// channel. Defaults to the real launcher.
  final ExternalUrlOpener openUrl;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    var opened = false;
    try {
      opened = await openUrl(url);
    } on Exception {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsLegalLinkError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SettingsField(
        icon: icon,
        label: label,
        sublabel: sublabel,
        onTap: () => unawaited(_open(context)),
      );
}
