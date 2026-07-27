import 'dart:convert';

import 'package:billetudo/features/auth/data/datasources/auth_nonce.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthNonce.generate', () {
    test(
        'hashed is the lowercase hex SHA-256 of raw (what the provider gets '
        'vs. what Supabase re-hashes)', () {
      final nonce = AuthNonce.generate();

      final expected = sha256.convert(utf8.encode(nonce.raw)).toString();
      expect(nonce.hashed, expected);
      // 32-byte digest as hex.
      expect(nonce.hashed, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('produces a fresh raw nonce on every call (replay protection)', () {
      final raws = List.generate(50, (_) => AuthNonce.generate().raw);

      expect(raws.toSet().length, raws.length);
      // Never empty: an empty nonce would read to Supabase as "no nonce".
      expect(raws.every((raw) => raw.isNotEmpty), isTrue);
    });
  });
}
