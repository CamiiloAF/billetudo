import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/onboarding_status_badge.dart';
import '../widgets/onboarding_wallet_fan.dart';

/// HU-04 (`Gi0NV`/`Bylcp`), with the `accountSkipped` variant `bAKS6`/`ld3xh`:
/// "Tu billetera está lista" — the last screen, closing the flow no matter
/// which primary action the user takes (`13-onboarding.md`, "Persistencia y
/// ciclo de vida del flujo": acting here, registering **or** skipping, is
/// what turns the `onboardingCompleted` latch on).
///
/// When [accountSkipped] is `true` the CTA cannot open the transaction form —
/// `Transactions.accountId` is `NOT NULL` — so it bridges to creating the
/// account instead, with `bAKS6`'s generic, gate-agnostic copy
/// (`docs/requirements/15-gate-cuenta.md` does not have its own design yet;
/// see the TODO below).
class ClosingPage extends StatelessWidget {
  const ClosingPage({
    required this.accountSkipped,
    required this.onPrimary,
    required this.onSkip,
    super.key,
  });

  /// Whether the user skipped "Tu primera cuenta" (HU-02).
  final bool accountSkipped;

  /// Registers the first transaction, or — when [accountSkipped] — bridges
  /// to creating the account.
  final VoidCallback onPrimary;

  /// "Lo hago después": leaves the flow without acting on the CTA.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return OnboardingScaffold(
      stepIndex: 3,
      primaryLabel: accountSkipped
          ? l10n.onboardingClosingCtaAccount
          : l10n.onboardingClosingCtaTransaction,
      primaryIcon: LucideIcons.plus,
      onPrimary: onPrimary,
      secondaryLabel: l10n.onboardingClosingSkip,
      onSecondary: onSkip,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingWalletFan(
            cardCount: 4,
            badge: OnboardingBadgeKind.check,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingClosingHeadline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            accountSkipped
                ? l10n.onboardingClosingSubheadNoAccount
                : l10n.onboardingClosingSubheadWithAccount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
