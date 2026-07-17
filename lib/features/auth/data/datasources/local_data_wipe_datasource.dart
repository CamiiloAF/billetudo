import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// HU-07 paso 2 ("Borrar también los datos de este dispositivo"): erases
/// every row on this device, across every table. Only reachable after
/// `AuthRepository.deleteAccount` already removed the cloud copy, and only on
/// the user's explicit, unpreselected choice — never silently.
@lazySingleton
class LocalDataWipeDatasource {
  const LocalDataWipeDatasource(this._db);

  final AppDatabase _db;

  Future<void> wipeAll() => _db.transaction(() async {
        // Children before parents, though none of this enforces FKs at the
        // SQLite level today — order kept for readability and in case that
        // changes.
        await _db.delete(_db.transactionTags).go();
        await _db.delete(_db.transactions).go();
        await _db.delete(_db.scheduledPayments).go();
        await _db.delete(_db.debts).go();
        await _db.delete(_db.goals).go();
        await _db.delete(_db.budgets).go();
        await _db.delete(_db.tags).go();
        await _db.delete(_db.categories).go();
        await _db.delete(_db.accounts).go();
      });
}
