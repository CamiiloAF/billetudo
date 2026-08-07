import '../../../../core/database/app_database.dart' as db;
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/csv_vocabulary.dart';
import 'decimal_amount_parser.dart';

/// Everything [TransactionCsvMapper.toRow] needs about a transaction's
/// related rows, already resolved by the caller (a page's worth of lookups,
/// not a query per row).
class TransactionCsvContext {
  const TransactionCsvContext({
    required this.accountNames,
    required this.categoryNames,
    required this.categoryParentIds,
    required this.tagNamesByTransactionId,
  });

  final Map<String, String> accountNames;
  final Map<String, String> categoryNames;
  final Map<String, String?> categoryParentIds;
  final Map<String, List<String>> tagNamesByTransactionId;
}

/// Builds one HU-01 CSV row from a `Transactions` row. `data/`-only: never
/// exposes `db.Transaction` outside this feature's data layer.
abstract final class TransactionCsvMapper {
  static List<String> toRow(
    db.Transaction row, {
    required TransactionCsvContext context,
    required CsvVocabulary vocabulary,
  }) {
    final rootId = row.categoryId == null
        ? null
        : (context.categoryParentIds[row.categoryId] ?? row.categoryId);
    final isSubcategory = row.categoryId != null && rootId != row.categoryId;

    final values = <TransactionCsvColumn, String>{
      TransactionCsvColumn.id: row.id,
      TransactionCsvColumn.date: _isoDate(row.date),
      TransactionCsvColumn.type: _typeLabel(row.type, vocabulary),
      // Deliberately not `MoneyFormatter.currencyDecimals` — that is a
      // *display* value (0 for COP) and would drop two zeros off every COP
      // amount. `amountMinor` is always cents regardless of currency, so
      // the CSV round-trips through the storage scale
      // (`MoneyFormatter.inputDecimals`), never the display one.
      TransactionCsvColumn.amount: DecimalAmountParser.format(
        row.amountMinor,
        currencyDecimals: MoneyFormatter.inputDecimals(row.currency),
      ),
      TransactionCsvColumn.currency: row.currency,
      TransactionCsvColumn.account: context.accountNames[row.accountId] ?? '',
      TransactionCsvColumn.transferAccount: row.transferAccountId == null
          ? ''
          : context.accountNames[row.transferAccountId] ?? '',
      TransactionCsvColumn.category: rootId == null
          ? ''
          : context.categoryNames[rootId] ?? '',
      TransactionCsvColumn.subcategory: isSubcategory
          ? context.categoryNames[row.categoryId] ?? ''
          : '',
      TransactionCsvColumn.note: row.note ?? '',
      TransactionCsvColumn.tags:
          (context.tagNamesByTransactionId[row.id] ?? const []).join(';'),
      TransactionCsvColumn.budgetable:
          row.countsInBudget ? vocabulary.yesValue : vocabulary.noValue,
      TransactionCsvColumn.source: vocabulary.sourceLabels[_sourceOf(row.source)]!,
    };
    return [for (final column in TransactionCsvColumn.values) values[column]!];
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _typeLabel(db.EntryType type, CsvVocabulary vocabulary) =>
      switch (type) {
        db.EntryType.income => vocabulary.typeValues.income,
        db.EntryType.expense => vocabulary.typeValues.expense,
        db.EntryType.transfer => vocabulary.typeValues.transfer,
      };

  static CsvTxSource _sourceOf(db.TxSource source) => switch (source) {
        db.TxSource.manual => CsvTxSource.manual,
        db.TxSource.voice => CsvTxSource.voice,
        db.TxSource.ocr => CsvTxSource.ocr,
        db.TxSource.notification => CsvTxSource.notification,
        db.TxSource.imported => CsvTxSource.imported,
        db.TxSource.scheduled => CsvTxSource.scheduled,
      };
}
