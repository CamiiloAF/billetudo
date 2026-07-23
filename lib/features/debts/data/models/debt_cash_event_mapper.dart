import '../../../../core/database/app_database.dart' as db;
import '../../../transactions/data/models/transaction_mapper.dart';
import '../../domain/entities/debt_cash_event.dart';

/// Projects a Drift `Transaction` row that carries a debt id into the minimal
/// [DebtCashEvent] the debt derivation needs. Reuses the Transacciones mapper's
/// `EntryType` -> `TransactionType` mapping so the enum translation has a single
/// home (same precedent as `scheduled_payments/data`).
abstract final class DebtCashEventMapper {
  static DebtCashEvent toEntity(db.Transaction row) => DebtCashEvent(
        transactionId: row.id,
        type: TransactionMapper.typeToDomain(row.type),
        amountMinor: row.amountMinor,
        date: row.date,
        note: row.note,
      );
}
