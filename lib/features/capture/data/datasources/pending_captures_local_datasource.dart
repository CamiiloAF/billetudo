import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Drift queries over `PendingCaptures` (the review inbox) plus the two
/// lookups the inbox needs against other tables: possible duplicates in
/// `Transactions` and the last-4 match in `Accounts`.
///
/// A plain injected class instead of a `@DriftAccessor`, same reasoning as
/// the other feature datasources: no new tables, no forced schema
/// regeneration.
///
/// Nothing here ever writes notification content, because none reaches this
/// layer: the row shape simply has no column for it (HU-03).
@lazySingleton
class PendingCapturesLocalDatasource {
  const PendingCapturesLocalDatasource(this._db);

  final AppDatabase _db;

  Expression<bool> _alive($PendingCapturesTable t) =>
      t.deletedAt.isNull() & t.tombstonedAt.isNull();

  /// The inbox: only `pending`, newest posting first. `createdAt` breaks ties
  /// so two captures posted in the same second keep a stable order instead of
  /// swapping places between rebuilds.
  Stream<List<PendingCapture>> watchPendingCaptures() {
    final query = _db.select(_db.pendingCaptures)
      ..where(
        (t) => _alive(t) & t.status.equalsValue(CaptureStatus.pending),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.postedAt),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    return query.watch();
  }

  /// Count of the exact same set [watchPendingCaptures] returns.
  Stream<int> watchPendingCaptureCount() {
    final count = _db.pendingCaptures.id.count();
    final query = _db.selectOnly(_db.pendingCaptures)
      ..addColumns([count])
      ..where(
        _alive(_db.pendingCaptures) &
            _db.pendingCaptures.status.equalsValue(CaptureStatus.pending),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<List<PendingCapture>> insertCaptures(
    List<PendingCapturesCompanion> companions,
  ) =>
      _db.transaction(() async {
        final inserted = <PendingCapture>[];
        for (final companion in companions) {
          inserted.add(
            await _db.into(_db.pendingCaptures).insertReturning(companion),
          );
        }
        return inserted;
      });

  Future<PendingCapture?> getCapture(String id) =>
      (_db.select(_db.pendingCaptures)
            ..where((t) => _alive(t) & t.id.equals(id)))
          .getSingleOrNull();

  /// Returns the updated row, or `null` when [id] matches no live capture —
  /// so the repository can tell "not found" from "updated" instead of
  /// reporting a silent success.
  Future<PendingCapture?> updateCapture(
    String id,
    PendingCapturesCompanion companion,
  ) async {
    final updated = await (_db.update(_db.pendingCaptures)
          ..where((t) => _alive(t) & t.id.equals(id)))
        .writeReturning(companion);
    return updated.isEmpty ? null : updated.first;
  }

  /// The `pending` captures posted strictly before [postedBefore], for the
  /// batch discard of HU-10.
  Future<List<PendingCapture>> pendingCapturesBefore(DateTime postedBefore) =>
      (_db.select(_db.pendingCaptures)
            ..where(
              (t) =>
                  _alive(t) &
                  t.status.equalsValue(CaptureStatus.pending) &
                  t.postedAt.isSmallerThanValue(postedBefore),
            ))
          .get();

  /// PHYSICAL delete of the captures discarded before [updatedBefore] (past
  /// the undo window). Not a soft delete on purpose — see
  /// `PurgeDiscardedCaptures`.
  Future<int> deleteDiscardedBefore(DateTime updatedBefore) =>
      (_db.delete(_db.pendingCaptures)
            ..where(
              (t) =>
                  t.status.equalsValue(CaptureStatus.discarded) &
                  t.updatedAt
                      .isSmallerThanValue(updatedBefore.millisecondsSinceEpoch),
            ))
          .go();

  /// PHYSICAL delete of every capture row, whatever its status (HU-08).
  Future<int> deleteAllCaptures() => _db.delete(_db.pendingCaptures).go();

  /// Live transactions with the same amount and currency inside
  /// [from]..[to], as duplicate candidates (HU-07). Read-only.
  Future<List<Transaction>> findMatchingTransactions({
    required int amountMinor,
    required String currency,
    required DateTime from,
    required DateTime to,
  }) =>
      (_db.select(_db.transactions)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.tombstonedAt.isNull() &
                  t.amountMinor.equals(amountMinor) &
                  t.currency.equals(currency) &
                  t.date.isBiggerOrEqualValue(from) &
                  t.date.isSmallerOrEqualValue(to),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  /// Other `pending` captures with the same amount and currency inside
  /// [from]..[to]. Deliberately NOT filtered by `sourcePackage`: the wallet
  /// and the bank of one NFC payment are two different packages (HU-07).
  Future<List<PendingCapture>> findMatchingCaptures({
    required String excludeId,
    required int amountMinor,
    required String currency,
    required DateTime from,
    required DateTime to,
  }) =>
      (_db.select(_db.pendingCaptures)
            ..where(
              (t) =>
                  _alive(t) &
                  t.status.equalsValue(CaptureStatus.pending) &
                  t.id.equals(excludeId).not() &
                  t.amountMinor.equals(amountMinor) &
                  t.currency.equals(currency) &
                  t.postedAt.isBiggerOrEqualValue(from) &
                  t.postedAt.isSmallerOrEqualValue(to),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.postedAt)]))
          .get();

  /// Live accounts whose card last-4 equals [hint].
  Future<List<Account>> accountsByCardLast4(String hint) =>
      (_db.select(_db.accounts)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.tombstonedAt.isNull() &
                  t.cardLast4.equals(hint),
            ))
          .get();

  /// Live accounts whose account last-4 equals [hint].
  Future<List<Account>> accountsByLast4(String hint) =>
      (_db.select(_db.accounts)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.tombstonedAt.isNull() &
                  t.last4.equals(hint),
            ))
          .get();

  Future<Transaction> insertTransaction(TransactionsCompanion companion) =>
      _db.into(_db.transactions).insertReturning(companion);

  /// Runs [body] inside a single database transaction, so confirming a
  /// capture cannot leave the transaction created without the capture marked
  /// (or the other way round).
  Future<T> runInTransaction<T>(Future<T> Function() body) =>
      _db.transaction(body);
}
