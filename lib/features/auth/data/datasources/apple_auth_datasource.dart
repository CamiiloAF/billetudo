import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/social_credential.dart';

/// Thrown when the user dismisses the Apple sign-in sheet.
class AppleAuthCancelledException implements Exception {
  const AppleAuthCancelledException();
}

/// Real Sign in with Apple integration (HU-03, iOS only). Uses the official
/// `sign_in_with_apple` package end to end (never a third-party icon font for
/// the glyph — see `design-system/billetudo/pages/auth.md`).
///
/// Apple only ever returns the user's name/email on the *first* authorization
/// — the mapped [SocialCredential.displayName] falls back to the opaque
/// `userIdentifier` on subsequent sign-ins, same as Apple's own guidance.
@lazySingleton
class AppleAuthDatasource {
  Future<SocialCredential> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.fullName,
          AppleIDAuthorizationScopes.email,
        ],
      );
      final name = [credential.givenName, credential.familyName]
          .whereType<String>()
          .join(' ')
          .trim();
      return SocialCredential(
        providerUserId: credential.userIdentifier ?? credential.state ?? '',
        displayName: name.isNotEmpty ? name : credential.userIdentifier ?? '',
        email: credential.email,
        idToken: credential.identityToken,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AppleAuthCancelledException();
      }
      rethrow;
    }
  }
}
