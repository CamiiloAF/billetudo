import '../../../../core/database/app_database.dart' as db;
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/csv_vocabulary.dart';
import 'decimal_amount_parser.dart';

/// Builds one HU-02 CSV row from an `Accounts` row. Never includes
/// `accountNumberEnc` — that column does not even exist on this table (it
/// lives only in secure storage, HU-03 of `01-cuentas.md`); `last4` is the
/// only account-number fragment that ever leaves the device.
///
/// `AccountType`'s own English name is exported as `tipo` regardless of
/// [CsvVocabulary.language] — it is a short technical token (`bank`, `card`)
/// that this export never reads back (HU-05 imports transactions only,
/// accounts are only ever matched by *name*), so translating it would add
/// two more vocabularies for zero round-trip benefit.
abstract final class AccountCsvMapper {
  static List<String> toRow(db.Account row, {required CsvVocabulary vocabulary}) {
    final values = <AccountCsvColumn, String>{
      AccountCsvColumn.id: row.id,
      AccountCsvColumn.name: row.name,
      AccountCsvColumn.type: row.type.name,
      AccountCsvColumn.currency: row.currency,
      // Deliberately not `MoneyFormatter.currencyDecimals` — see
      // `creditLimit` below for why the storage scale, not the display one,
      // is what the CSV boundary needs.
      AccountCsvColumn.openingBalance: DecimalAmountParser.format(
        row.initialBalanceMinor,
        currencyDecimals: MoneyFormatter.inputDecimals(row.currency),
      ),
      AccountCsvColumn.institution: row.institution ?? '',
      AccountCsvColumn.last4: row.last4 ?? '',
      AccountCsvColumn.archived:
          row.archived ? vocabulary.yesValue : vocabulary.noValue,
      AccountCsvColumn.sortOrder: row.sortOrder.toString(),
      AccountCsvColumn.icon: row.icon ?? '',
      AccountCsvColumn.color: row.color ?? '',
      AccountCsvColumn.annualInterestRate: row.interestRateBps == null
          ? ''
          : DecimalAmountParser.format(row.interestRateBps!, currencyDecimals: 2),
      // `creditLimitMinor` is stored in cents for every currency (`CLAUDE.md`:
      // "Dinero: SIEMPRE enteros en unidades menores"), so this needs the
      // storage scale (`inputDecimals`, always 2), not `currencyDecimals`
      // (COP's *display* scale is 0, which would multiply a COP credit
      // limit by 100 on export/import).
      AccountCsvColumn.creditLimit: row.creditLimitMinor == null
          ? ''
          : DecimalAmountParser.format(
              row.creditLimitMinor!,
              currencyDecimals: MoneyFormatter.inputDecimals(row.currency),
            ),
      AccountCsvColumn.statementDay: row.statementDay?.toString() ?? '',
      AccountCsvColumn.paymentDueDay: row.paymentDueDay?.toString() ?? '',
    };
    return [for (final column in AccountCsvColumn.values) values[column]!];
  }
}
