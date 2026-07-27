import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A single-use nonce pair for a native OpenID Connect sign-in.
///
/// The [hashed] value (SHA-256 of [raw], lowercase hex) is what the provider
/// receives and embeds in the returned `idToken`'s `nonce` claim; the [raw]
/// value is what Supabase's `signInWithIdToken` needs so it can re-hash and
/// compare. Supplying one without the other makes the exchange fail with
/// "Passed nonce and nonce in id_token should either both exist or not", which
/// is the iOS Google sign-in bug this type exists to prevent.
class AuthNonce {
  const AuthNonce({required this.raw, required this.hashed});

  /// Builds a fresh nonce from a cryptographically-strong random source. Call
  /// once per sign-in attempt — reusing a nonce defeats its replay protection.
  factory AuthNonce.generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final raw = base64UrlEncode(bytes);
    return AuthNonce(raw: raw, hashed: _sha256Hex(raw));
  }

  /// The un-hashed nonce, handed to Supabase alongside the `idToken`.
  final String raw;

  /// The SHA-256 hex digest of [raw], handed to the provider SDK.
  final String hashed;

  static String _sha256Hex(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
