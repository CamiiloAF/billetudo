import 'package:equatable/equatable.dart';

import 'column_mapping.dart';

/// Which of the two vocabularies a CSV file's headers/values are written in.
/// Export always picks one from the active app language; import recognizes
/// either, so a Spanish-exported file re-imports unmodified into an
/// English-language install (`docs/requirements/11-import-export.md`
/// §Encabezados y nombres de archivo).
enum CsvLanguage { es, en }

/// HU-01's exact transaction column order.
enum TransactionCsvColumn {
  id,
  date,
  type,
  amount,
  currency,
  account,
  transferAccount,
  category,
  subcategory,
  note,
  tags,
  budgetable,
  source,
}

/// HU-02's exact account column order.
enum AccountCsvColumn {
  id,
  name,
  type,
  currency,
  openingBalance,
  institution,
  last4,
  archived,
  sortOrder,
  icon,
  color,
  annualInterestRate,
  creditLimit,
  statementDay,
  paymentDueDay,
}

/// HU-02's exact category column order.
enum CategoryCsvColumn { id, name, type, parentCategory, parentId, icon, color, sortOrder }

/// Mirrors `TxSource` (`03-transacciones.md` HU-08), for the export-only
/// `origen` column — never imported back (HU-05's `ImportField` has no
/// counterpart for it; every imported row is unconditionally `imported`).
enum CsvTxSource { manual, voice, ocr, notification, imported, scheduled }

/// The literal header/value strings for one [CsvLanguage] — the file
/// format's own vocabulary, not app UI copy (headers land in a CSV, read by
/// Excel/Sheets/other tools, never inside a Flutter widget). Declared here,
/// not sourced from `AppLocalizations`, because both directions of HU-05's
/// "reconoce ambos vocabularios" have to exist independent of the device's
/// current language.
class CsvVocabulary extends Equatable {
  const CsvVocabulary({
    required this.language,
    required this.transactionHeaders,
    required this.accountHeaders,
    required this.categoryHeaders,
    required this.typeValues,
    required this.yesValue,
    required this.noValue,
    required this.sourceLabels,
  });

  final CsvLanguage language;
  final Map<TransactionCsvColumn, String> transactionHeaders;
  final Map<AccountCsvColumn, String> accountHeaders;
  final Map<CategoryCsvColumn, String> categoryHeaders;
  final TypeColumnValues typeValues;
  final String yesValue;
  final String noValue;
  final Map<CsvTxSource, String> sourceLabels;

  List<String> get transactionHeaderRow =>
      TransactionCsvColumn.values.map((c) => transactionHeaders[c]!).toList();

  List<String> get accountHeaderRow =>
      AccountCsvColumn.values.map((c) => accountHeaders[c]!).toList();

  List<String> get categoryHeaderRow =>
      CategoryCsvColumn.values.map((c) => categoryHeaders[c]!).toList();

  static const CsvVocabulary es = CsvVocabulary(
    language: CsvLanguage.es,
    transactionHeaders: {
      TransactionCsvColumn.id: 'id',
      TransactionCsvColumn.date: 'fecha',
      TransactionCsvColumn.type: 'tipo',
      TransactionCsvColumn.amount: 'monto',
      TransactionCsvColumn.currency: 'moneda',
      TransactionCsvColumn.account: 'cuenta',
      TransactionCsvColumn.transferAccount: 'cuenta_destino',
      TransactionCsvColumn.category: 'categoria',
      TransactionCsvColumn.subcategory: 'subcategoria',
      TransactionCsvColumn.note: 'nota',
      TransactionCsvColumn.tags: 'etiquetas',
      TransactionCsvColumn.budgetable: 'presupuestable',
      TransactionCsvColumn.source: 'origen',
    },
    accountHeaders: {
      AccountCsvColumn.id: 'id',
      AccountCsvColumn.name: 'nombre',
      AccountCsvColumn.type: 'tipo',
      AccountCsvColumn.currency: 'moneda',
      AccountCsvColumn.openingBalance: 'saldo_inicial',
      AccountCsvColumn.institution: 'institucion',
      AccountCsvColumn.last4: 'last4',
      AccountCsvColumn.archived: 'archivada',
      AccountCsvColumn.sortOrder: 'orden',
      AccountCsvColumn.icon: 'icono',
      AccountCsvColumn.color: 'color',
      AccountCsvColumn.annualInterestRate: 'tasa_interes_anual',
      AccountCsvColumn.creditLimit: 'cupo',
      AccountCsvColumn.statementDay: 'dia_corte',
      AccountCsvColumn.paymentDueDay: 'dia_pago',
    },
    categoryHeaders: {
      CategoryCsvColumn.id: 'id',
      CategoryCsvColumn.name: 'nombre',
      CategoryCsvColumn.type: 'tipo',
      CategoryCsvColumn.parentCategory: 'categoria_padre',
      CategoryCsvColumn.parentId: 'id_padre',
      CategoryCsvColumn.icon: 'icono',
      CategoryCsvColumn.color: 'color',
      CategoryCsvColumn.sortOrder: 'orden',
    },
    typeValues: TypeColumnValues(
      income: 'ingreso',
      expense: 'gasto',
      transfer: 'transferencia',
    ),
    yesValue: 'sí',
    noValue: 'no',
    sourceLabels: {
      CsvTxSource.manual: 'manual',
      CsvTxSource.voice: 'voz',
      CsvTxSource.ocr: 'ocr',
      CsvTxSource.notification: 'notificación',
      CsvTxSource.imported: 'importado',
      CsvTxSource.scheduled: 'programado',
    },
  );

  static const CsvVocabulary en = CsvVocabulary(
    language: CsvLanguage.en,
    transactionHeaders: {
      TransactionCsvColumn.id: 'id',
      TransactionCsvColumn.date: 'date',
      TransactionCsvColumn.type: 'type',
      TransactionCsvColumn.amount: 'amount',
      TransactionCsvColumn.currency: 'currency',
      TransactionCsvColumn.account: 'account',
      TransactionCsvColumn.transferAccount: 'transfer_account',
      TransactionCsvColumn.category: 'category',
      TransactionCsvColumn.subcategory: 'subcategory',
      TransactionCsvColumn.note: 'note',
      TransactionCsvColumn.tags: 'tags',
      TransactionCsvColumn.budgetable: 'budgetable',
      TransactionCsvColumn.source: 'source',
    },
    accountHeaders: {
      AccountCsvColumn.id: 'id',
      AccountCsvColumn.name: 'name',
      AccountCsvColumn.type: 'type',
      AccountCsvColumn.currency: 'currency',
      AccountCsvColumn.openingBalance: 'opening_balance',
      AccountCsvColumn.institution: 'institution',
      AccountCsvColumn.last4: 'last4',
      AccountCsvColumn.archived: 'archived',
      AccountCsvColumn.sortOrder: 'sort_order',
      AccountCsvColumn.icon: 'icon',
      AccountCsvColumn.color: 'color',
      AccountCsvColumn.annualInterestRate: 'annual_interest_rate',
      AccountCsvColumn.creditLimit: 'credit_limit',
      AccountCsvColumn.statementDay: 'statement_day',
      AccountCsvColumn.paymentDueDay: 'payment_due_day',
    },
    categoryHeaders: {
      CategoryCsvColumn.id: 'id',
      CategoryCsvColumn.name: 'name',
      CategoryCsvColumn.type: 'type',
      CategoryCsvColumn.parentCategory: 'parent_category',
      CategoryCsvColumn.parentId: 'parent_id',
      CategoryCsvColumn.icon: 'icon',
      CategoryCsvColumn.color: 'color',
      CategoryCsvColumn.sortOrder: 'sort_order',
    },
    typeValues: TypeColumnValues(
      income: 'income',
      expense: 'expense',
      transfer: 'transfer',
    ),
    yesValue: 'yes',
    noValue: 'no',
    sourceLabels: {
      CsvTxSource.manual: 'manual',
      CsvTxSource.voice: 'voice',
      CsvTxSource.ocr: 'ocr',
      CsvTxSource.notification: 'notification',
      CsvTxSource.imported: 'imported',
      CsvTxSource.scheduled: 'scheduled',
    },
  );

  static const List<CsvVocabulary> all = [es, en];

  @override
  List<Object?> get props => [language];
}
