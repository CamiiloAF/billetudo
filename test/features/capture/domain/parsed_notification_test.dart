import 'package:billetudo/features/capture/domain/entities/parsed_notification.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedNotification capture({
  required String issuerId,
  required TransactionType entryType,
  int amountMinor = 100,
  String currency = 'COP',
  DateTime? postedAt,
  String? merchant,
  String? accountHint,
}) =>
    ParsedNotification(
      issuerId: issuerId,
      sourcePackage: 'com.example.$issuerId',
      ruleId: '$issuerId.rule',
      amountMinor: amountMinor,
      currency: currency,
      entryType: entryType,
      postedAt: postedAt ?? DateTime(2026, 9, 9, 12),
      merchantRaw: merchant,
      accountHint: accountHint,
    );

void main() {
  group('suggested note', () {
    test('is composed only of identified fields', () {
      final ParsedNotification result = capture(
        issuerId: 'google_wallet',
        entryType: TransactionType.expense,
        merchant: 'DROGUERIA LAS 24',
        accountHint: '5615',
      );
      expect(result.noteParts, <String>['DROGUERIA LAS 24', '*5615']);
      expect(result.suggestedNote, 'DROGUERIA LAS 24 · *5615');
    });

    test('stays empty when no field was identified', () {
      final ParsedNotification result = capture(
        issuerId: 'nequi',
        entryType: TransactionType.income,
      );
      expect(result.noteParts, isEmpty);
      expect(result.suggestedNote, isEmpty);
    });
  });

  group('grouping candidates', () {
    test('groups wallet and issuer: same amount, same instant, both expenses',
        () {
      final DateTime now = DateTime(2026, 9, 9, 12);
      final ParsedNotification wallet = capture(
        issuerId: 'google_wallet',
        entryType: TransactionType.expense,
        amountMinor: 3800000,
        postedAt: now,
        merchant: 'DROGUERIA LAS 24',
      );
      final ParsedNotification bank = capture(
        issuerId: 'nu',
        entryType: TransactionType.expense,
        amountMinor: 3800000,
        postedAt: now.add(const Duration(seconds: 20)),
        accountHint: '5615',
      );
      expect(wallet.canGroupWith(bank), isTrue);
    });

    test('NEVER groups opposite types, even at the same amount and instant',
        () {
      // Moving money from the user's own Nu to their own Nequi fires two
      // notifications of $1 at the same second: one expense and one income.
      // They are two real movements in two accounts; merging them would erase
      // one of them.
      final DateTime now = DateTime(2026, 9, 9, 12);
      final ParsedNotification nuOut = capture(
        issuerId: 'nu',
        entryType: TransactionType.expense,
        postedAt: now,
      );
      final ParsedNotification nequiIn = capture(
        issuerId: 'nequi',
        entryType: TransactionType.income,
        postedAt: now,
      );
      expect(nuOut.canGroupWith(nequiIn), isFalse);
      expect(nequiIn.canGroupWith(nuOut), isFalse);
    });

    test('does not group a different amount or a different currency', () {
      final DateTime now = DateTime(2026, 9, 9, 12);
      final ParsedNotification a = capture(
        issuerId: 'nu',
        entryType: TransactionType.expense,
        amountMinor: 100,
        postedAt: now,
      );
      expect(
        a.canGroupWith(
          capture(
            issuerId: 'nequi',
            entryType: TransactionType.expense,
            amountMinor: 200,
            postedAt: now,
          ),
        ),
        isFalse,
      );
      expect(
        a.canGroupWith(
          capture(
            issuerId: 'nequi',
            entryType: TransactionType.expense,
            currency: 'USD',
            postedAt: now,
          ),
        ),
        isFalse,
      );
    });

    test('does not group outside the window', () {
      final DateTime now = DateTime(2026, 9, 9, 12);
      expect(
        capture(
          issuerId: 'nu',
          entryType: TransactionType.expense,
          postedAt: now,
        ).canGroupWith(
          capture(
            issuerId: 'nequi',
            entryType: TransactionType.expense,
            postedAt: now.add(const Duration(hours: 2)),
          ),
        ),
        isFalse,
      );
    });
  });
}
