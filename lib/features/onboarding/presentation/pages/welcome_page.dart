import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/onboarding_wallet_fan.dart';

/// HU-01 (`fRrDQ`/`mmFVh`): "Todo lo esencial. Gratis. Para siempre." — the
/// only screen of the flow with no back button (it is the first step) and no
/// badge on its wallet-card hero (there is nothing to confirm yet).
///
/// `13-onboarding.md`, "Navegación": the system back button here must not
/// leave the user at a half-built Home — it minimizes the app instead, same
/// intent as `HomeShellPage`'s own `PopScope`, just without its confirm
/// dialog (that is Home's own choice for an established session, not this
/// first-run screen's).
class WelcomePage extends StatelessWidget {
  const WelcomePage({
    required this.onComenzar,
    required this.onYaTengoCuenta,
    super.key,
  });

  final VoidCallback onComenzar;
  final VoidCallback onYaTengoCuenta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(SystemNavigator.pop());
        }
      },
      child: OnboardingScaffold(
        stepIndex: 0,
        showBack: false,
        primaryLabel: l10n.onboardingWelcomeCta,
        primaryIcon: LucideIcons.arrowRight,
        onPrimary: onComenzar,
        secondaryLabel: l10n.onboardingAlreadyHaveAccount,
        onSecondary: onYaTengoCuenta,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OnboardingWalletFan(cardCount: 2),
            const SizedBox(height: 8),
            Text(
              l10n.onboardingWelcomeHeadline,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.12,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.onboardingWelcomeSubhead,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.onboardingWelcomeCaption,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primaryOnSoftStrong,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
