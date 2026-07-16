import 'package:flutter/material.dart';

import 'google_logo_mark.dart';

/// `Button/Google` (`FJ4Yl` in `billetudo.pen`): the `neutral` style from
/// Google's Identity branding guidelines — white surface, gray border, fixed
/// `#1F1F1F` text — deliberately **not** billetudo's `$primary`/Plus Jakarta
/// Sans (documented exception in `design-system/billetudo/pages/auth.md`).
///
/// Height 50 / radius 12, matching `Auth/Sign-in Buttons Group`. Shows a
/// spinner in place of the logo while [isLoading] (design ref `QD8kh`).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          side: const BorderSide(color: Color(0xFFDADCE0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1F1F1F),
                ),
              )
            else
              const GoogleLogoMark(),
            const SizedBox(width: 12),
            Text(
              label,
              // 'Roboto' isn't bundled in assets/fonts/ (only Plus Jakarta
              // Sans is, see pubspec.yaml) — this falls back to the platform
              // default, which is Roboto on Android anyway. Both brand
              // guidelines forbid the app's own typeface here regardless.
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
