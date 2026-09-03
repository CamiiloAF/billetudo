import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_header.dart';

/// The assistant's session gate: shown instead of the chat while
/// `AiChatState.isSignedIn` is `false`, so the composer never becomes
/// reachable for a request the backend (`verify_jwt: true`) would reject
/// anyway (see `AiChatCubit`'s auth subscription).
///
/// No `billetudo.pen` frame exists for this screen — same situation as
/// `AiConsentPage`, which this mirrors: the icon-circle-title-body-CTA shape
/// `EmptyState` already uses elsewhere, rather than a one-off layout. Both
/// should go through Pencil in a follow-up pass instead of staying one-offs.
class AiSignedOutPage extends StatelessWidget {
  const AiSignedOutPage({
    required this.onBack,
    required this.onSignIn,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.aiSignedOutTitle, onBack: onBack),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: colors.primarySoft,
                          borderRadius: BorderRadius.circular(44),
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          size: 40,
                          color: colors.primaryOnSoft,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.aiSignedOutHeadline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.aiSignedOutBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onSignIn,
                          child: Text(l10n.syncSignInCta),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
