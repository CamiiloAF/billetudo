import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/onboarding_status_badge.dart';
import '../widgets/onboarding_wallet_fan.dart';

/// HU-07 (`MydOr`/`DfHXL`): "Respalda tus datos, cuando quieras".
///
/// Never shown when the user already authenticated via "Ya tengo cuenta"
/// (HU-06) — the router skips straight to `ClosingPage` in that case
/// ("no repetir el mensaje tres veces", `13-onboarding.md` HU-07).
class BackupIntroPage extends StatelessWidget {
  const BackupIntroPage({
    required this.onActivarRespaldo,
    required this.onDespues,
    super.key,
  });

  /// Opens the existing login/backup screen (`AppRoutes.login`, reused).
  final VoidCallback onActivarRespaldo;

  /// Skips to the closing screen without authenticating.
  final VoidCallback onDespues;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return OnboardingScaffold(
      stepIndex: 2,
      primaryLabel: l10n.onboardingBackupCta,
      primaryIcon: LucideIcons.cloud,
      onPrimary: onActivarRespaldo,
      secondaryLabel: l10n.onboardingBackupSkip,
      onSecondary: onDespues,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingWalletFan(
            cardCount: 3,
            badge: OnboardingBadgeKind.cloud,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingBackupHeadline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.onboardingBackupBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.onboardingBackupFootnote,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
