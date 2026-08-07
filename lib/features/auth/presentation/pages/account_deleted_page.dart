import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/delete_account_scope.dart';

/// HU-07 paso 3 (`sqm4I`): the closing screen of account deletion, neutral
/// tone. Only [DeleteAccountScope.cloudAndLocal] talks about the cloud —
/// that is the one scope where this run actually contacted the server and
/// can truthfully say the cloud account is gone.
///
/// [DeleteAccountScope.localOnlySignedOut] and
/// [DeleteAccountScope.localOnlyNeverSignedIn] both stay local-only, but for
/// different reasons and with different copy:
/// - `localOnlySignedOut`: this device signed out of a real cloud account
///   and this run never reached it, so the screen must say only local data
///   was cleared instead of implying the cloud account is gone (paso 1's
///   `ConfirmDeleteAccountSheet` already warned about this before the user
///   chose to continue).
/// - `localOnlyNeverSignedIn`: `everSignedIn` is a local-only flag with no
///   server check, so this device may in fact have a real cloud account
///   (reinstall, second device, a sign-in race) that this run never
///   contacted. The copy must not claim "no data left in the cloud" —
///   that asserts something never verified — so it says only that this
///   device's local data was cleared, without mentioning the cloud at all.
class AccountDeletedPage extends StatelessWidget {
  const AccountDeletedPage({
    required this.scope,
    required this.onGoHome,
    super.key,
  });

  final DeleteAccountScope scope;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final isLocalOnlyAfterSignOut =
        scope == DeleteAccountScope.localOnlySignedOut;
    final isLocalOnlyNeverSignedIn =
        scope == DeleteAccountScope.localOnlyNeverSignedIn;
    final title = isLocalOnlyAfterSignOut
        ? l10n.authDeleteStep3LocalOnlyTitle
        : isLocalOnlyNeverSignedIn
            ? l10n.authDeleteStep3NeverSignedInTitle
            : l10n.authDeleteStep3Title;
    final subtitle = isLocalOnlyAfterSignOut
        ? l10n.authDeleteStep3LocalOnlySubtitle
        : isLocalOnlyNeverSignedIn
            ? l10n.authDeleteStep3NeverSignedInSubtitle
            : l10n.authDeleteStep3Subtitle;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.check,
                          size: 32,
                          color: colors.primaryOnSoft,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onGoHome,
                  child: Text(l10n.authDeleteStep3Cta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
