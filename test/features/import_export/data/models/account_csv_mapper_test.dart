import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/import_export/data/models/account_csv_mapper.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_vocabulary.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// HU-02: the accounts CSV row. Covers the privacy rule (no
/// `accountNumberEnc`, `last4` present) and the money columns
/// (`saldo_inicial`, `cupo`), which must reflect `amountMinor`/100 — the
/// storage scale `CLAUDE.md` fixes for every currency ("SIEMPRE enteros en
/// unidades menores/centavos") — regardless of a currency's own *display*
/// decimals (`MoneyFormatter.currencyDecimals` returns 0 for COP, which is a
/// display-only convention, not the stored scale; see
/// `MoneyFormatter._minorPerMajor == 100` for every currency).
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('nunca incluye accountNumberEnc; sí incluye last4', () async {
    final account = await db.into(db.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Bancolombia',
            type: AccountType.savings,
            currency: 'USD',
            last4: const Value('4321'),
          ),
        );

    final row = AccountCsvMapper.toRow(account, vocabulary: CsvVocabulary.es);

    expect(AccountCsvColumn.values.map((c) => c.name), isNot(contains('accountNumberEnc')));
    expect(row[AccountCsvColumn.last4.index], '4321');
  });

  test(
    'saldo_inicial en COP con centavos reales se exporta como decimal, no '
    'como el entero crudo de amountMinor',
    () async {
      // $19.99 COP: a real (if unusual) fractional COP balance — supported by
      // the schema/display layer (`MoneyFormatter` doc comment "item 4").
      final account = await db.into(db.accounts).insertReturning(
            AccountsCompanion.insert(
              name: 'Cuenta COP',
              type: AccountType.savings,
              currency: 'COP',
              initialBalanceMinor: const Value(1999),
            ),
          );

      final row = AccountCsvMapper.toRow(account, vocabulary: CsvVocabulary.es);

      expect(
        row[AccountCsvColumn.openingBalance.index],
        '19.99',
        reason: 'amountMinor is always centavos regardless of currency '
            '(CLAUDE.md); exporting it through the currency\'s *display* '
            'decimals (0 for COP) drops the decimal point entirely and '
            'writes the raw cents value as if it were whole pesos — a 100x '
            'magnitude error for any COP account with real cents.',
      );
    },
  );
}
