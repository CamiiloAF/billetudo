import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'google_sign_in_button.dart';

/// `Auth/Sign-in Buttons Group` (`rSSog`): Apple + Google + "Continuar sin
/// cuenta" skip link, stacked with a 12px gap.
///
/// Apple only ever shows on iOS (HU-03) — Android gets Google alone, exactly
/// like the `fTetG` (Android) vs `RSzD1` (iOS) instances in `billetudo.pen`.
/// Apple's button is the official `SignInWithAppleButton` widget: never a
/// third-party icon-font glyph in production code (see auth.md "Botones de
/// login — reglas de marca").
class AuthSignInButtonsGroup extends StatelessWidget {
  const AuthSignInButtonsGroup({
    required this.onGoogle,
    required this.onApple,
    required this.onSkip,
    this.isGoogleLoading = false,
    super.key,
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final VoidCallback onSkip;
  final bool isGoogleLoading;

  bool get _showApple => !kIsWeb && Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showApple) ...[
          SizedBox(
            height: 50,
            width: double.infinity,
            child: SignInWithAppleButton(
              onPressed: onApple ?? () {},
              text: l10n.authContinueWithApple,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
        ],
        GoogleSignInButton(
          label: l10n.authContinueWithGoogle,
          loadingLabel: l10n.authGoogleLoading,
          isLoading: isGoogleLoading,
          onPressed: onGoogle,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onSkip,
          child: Text(
            l10n.authContinueWithoutAccount,
            style: TextStyle(
              color: colors.primaryOnSoftStrong,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
