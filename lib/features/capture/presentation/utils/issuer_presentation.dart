import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Icon and colour pair of one issuer row.
class IssuerVisual {
  const IssuerVisual({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
}

/// How each catalogued issuer is drawn and described in the catalog screen.
///
/// Keyed by `issuerId` (the native side's key), not by package name: an
/// issuer can ship more than one package, and the id is what survives that.
///
/// **Everything unknown falls back**, on purpose. The catalog lives in
/// `assets/capture/issuer_rules.json` and grows in releases that this file
/// does not necessarily grow with; an issuer added there must render as a
/// plain bank row rather than crash or render blank. The display name never
/// comes from here — it comes from the catalog itself, since brand names are
/// not translated.
abstract final class IssuerPresentation {
  static IssuerVisual visual(String issuerId, AppColors colors) =>
      switch (issuerId) {
        'nu' => IssuerVisual(
            icon: LucideIcons.creditCard,
            foreground: colors.primaryOnSoft,
            background: colors.primarySoft,
          ),
        'nequi' => IssuerVisual(
            icon: LucideIcons.smartphone,
            foreground: colors.coral,
            background: colors.coralSoft,
          ),
        'google_wallet' => IssuerVisual(
            icon: LucideIcons.wallet,
            foreground: colors.sky,
            background: colors.skySoft,
          ),
        'bancolombia' => IssuerVisual(
            icon: LucideIcons.landmark,
            foreground: colors.amber,
            background: colors.amberSoft,
          ),
        _ => IssuerVisual(
            icon: LucideIcons.landmark,
            foreground: colors.textSecondary,
            background: colors.muted,
          ),
      };

  /// What is read from that app, in the user's words. Never the
  /// `packageName`: a technical string the user cannot act on.
  static String description(String issuerId, AppLocalizations l10n) =>
      switch (issuerId) {
        'nu' => l10n.captureIssuerNuDescription,
        'nequi' => l10n.captureIssuerNequiDescription,
        'google_wallet' => l10n.captureIssuerGoogleWalletDescription,
        _ => l10n.captureIssuerGenericDescription,
      };
}
