import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/parsed_capture.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ParsedCapture build({
    String sourcePackage = 'com.nu.production',
    int amountMinor = 4590000,
    String currency = 'cop',
    TransactionType entryType = TransactionType.expense,
    String? merchantRaw = '  EXITO CALLE 80 ',
    String? accountHint = '1234',
  }) =>
      ParsedCapture(
        sourcePackage: sourcePackage,
        postedAt: DateTime(2026, 9, 1, 12),
        amountMinor: amountMinor,
        currency: currency,
        entryType: entryType,
        merchantRaw: merchantRaw,
        accountHint: accountHint,
      );

  group('ParsedCapture.validated', () {
    test('normalizes currency and trims the extracted fragments', () {
      final result = build().validated();

      expect(result.isRight(), isTrue);
      final capture = result.getOrElse((_) => build());
      expect(capture.currency, 'COP');
      expect(capture.merchantRaw, 'EXITO CALLE 80');
      expect(capture.source, TransactionSource.notification);
    });

    test('turns a blank merchant into null instead of an empty key', () {
      final result = build(merchantRaw: '   ').validated();

      expect(result.getOrElse((_) => build()).merchantRaw, isNull);
    });

    test('refuses a non-positive amount: the sign belongs to the type', () {
      for (final amount in [0, -1]) {
        final result = build(amountMinor: amount).validated();

        expect(result.isLeft(), isTrue, reason: 'amount $amount');
        expect(
          result.getLeft().toNullable(),
          isA<ValidationFailure>().having(
            (failure) => failure.field,
            'field',
            ParsedCapture.fieldAmountMinor,
          ),
        );
      }
    });

    test('refuses a currency that is not an ISO-4217 code', () {
      expect(build(currency: 'PESOS').validated().isLeft(), isTrue);
      expect(build(currency: '').validated().isLeft(), isTrue);
    });

    test('refuses a transfer: a notification never names both accounts', () {
      final result = build(entryType: TransactionType.transfer).validated();

      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having(
          (failure) => failure.field,
          'field',
          ParsedCapture.fieldEntryType,
        ),
      );
    });

    test('refuses an account hint that is not four digits', () {
      expect(build(accountHint: '12345').validated().isLeft(), isTrue);
      expect(build(accountHint: '12a4').validated().isLeft(), isTrue);
      expect(build(accountHint: null).validated().isRight(), isTrue);
    });

    test('refuses a capture with no issuer package', () {
      expect(build(sourcePackage: '  ').validated().isLeft(), isTrue);
    });
  });
}
