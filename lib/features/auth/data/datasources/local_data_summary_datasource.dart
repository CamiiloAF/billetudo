import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/merge_summary.dart';

/// Counts what already lives on this device before it ever had an account —
/// the real, local half of HU-04 (the numbers shown on "Tus datos están a
/// salvo"). No Supabase involved: this only reads Drift, the source of truth.
@lazySingleton
class LocalDataSummaryDatasource {
  const LocalDataSummaryDatasource(this._db);

  final AppDatabase _db;

  Future<MergeSummary> getSummary() async {
    final accounts = await _countAccounts();
    final transactions = await _countTransactions();
    final categories = await _countCategories();

    return MergeSummary(
      accountsCount: accounts,
      transactionsCount: transactions,
      categoriesCount: categories,
    );
  }

  Future<int> _countAccounts() {
    final count = _db.accounts.id.count();
    final query = _db.selectOnly(_db.accounts)
      ..addColumns([count])
      ..where(_db.accounts.tombstonedAt.isNull());
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<int> _countTransactions() {
    final count = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([count])
      ..where(
        _db.transactions.deletedAt.isNull() &
            _db.transactions.tombstonedAt.isNull(),
      );
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<int> _countCategories() {
    final count = _db.categories.id.count();
    final query = _db.selectOnly(_db.categories)
      ..addColumns([count])
      ..where(_db.categories.tombstonedAt.isNull());
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }
}
