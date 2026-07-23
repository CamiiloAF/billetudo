import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/result.dart';
import '../../../transactions/data/models/transaction_mapper.dart';
import '../../../transactions/domain/entities/transaction.dart'
    show TransactionType;
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_accrual_context.dart';
import '../../domain/entities/debt_balance.dart';
import '../../domain/entities/debt_cash_event.dart';
import '../../domain/entities/debt_detail.dart';
import '../../domain/entities/debt_draft.dart';
import '../../domain/entities/debt_entry.dart';
import '../../domain/entities/debt_entry_draft.dart';
import '../../domain/entities/debt_with_balance.dart';
import '../../domain/entities/debts_summary.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/services/debt_balance_calculator.dart';
import '../datasources/debts_local_datasource.dart';
import '../models/debt_cash_event_mapper.dart';
import '../models/debt_entry_mapper.dart';
import '../models/debt_mapper.dart';

/// Drift implementation of [DebtRepository].
///
/// Owns the cross-cutting rules that `updatedAt` is stamped on **every** write
/// (via the mappers' companions) and that deletion is the reversible UX trash
/// (`deletedAt`, HU-05) — cascading onto the debt's `DebtEntries` but never onto
/// its cash `Transaction`s, which were real account movements. The outstanding
/// balance is never stored: it is derived by [DebtBalanceCalculator] from the
/// rows this repository gathers.
@LazySingleton(as: DebtRepository)
class DebtRepositoryImpl implements DebtRepository {
  const DebtRepositoryImpl(this._local, this._calculator);

  final DebtsLocalDatasource _local;
  final DebtBalanceCalculator _calculator;

  @override
  Stream<Result<DebtsSummary>> watchDebts() => _guardStream(
        _combineLatest(
          [
            _local.watchActiveDebts(),
            _local.watchActiveDebtEntries(),
            _local.watchActiveDebtCashEvents(),
          ],
          (values) {
            final debts = values[0]! as List<db.Debt>;
            final entries = values[1]! as List<db.DebtEntry>;
            final cashEvents = values[2]! as List<db.Transaction>;

            final entriesByDebt = _groupEntries(entries);
            final cashByDebt = _groupCashEvents(cashEvents);

            final withBalances = debts.map((row) {
              final debt = DebtMapper.toEntity(row);
              final balance = _calculator.calculate(
                debt: debt,
                entries: entriesByDebt[debt.id] ?? const [],
                cashEvents: cashByDebt[debt.id] ?? const [],
              );
              return DebtWithBalance(debt: debt, balance: balance);
            }).toList();

            return Right<Failure, DebtsSummary>(
              DebtsSummary.from(withBalances),
            );
          },
        ),
      );

  @override
  Stream<Result<DebtDetail>> watchDebtDetail(String debtId) => _guardStream(
        _combineLatest(
          [
            _local.watchDebt(debtId),
            _local.watchDebtEntries(debtId),
            _local.watchDebtCashEvents(debtId),
          ],
          (values) {
            final debtRow = values[0] as db.Debt?;
            if (debtRow == null) {
              return Left<Failure, DebtDetail>(
                NotFoundFailure('debt "$debtId" does not exist'),
              );
            }
            final entries =
                (values[1]! as List<db.DebtEntry>).map(DebtEntryMapper.toEntity).toList();
            final cashEvents = (values[2]! as List<db.Transaction>)
                .map(DebtCashEventMapper.toEntity)
                .toList();
            final debt = DebtMapper.toEntity(debtRow);

            return Right<Failure, DebtDetail>(
              DebtDetail(
                debt: debt,
                balance: _calculator.calculate(
                  debt: debt,
                  entries: entries,
                  cashEvents: cashEvents,
                ),
                ledger: _calculator.buildLedger(
                  debt: debt,
                  entries: entries,
                  cashEvents: cashEvents,
                ),
              ),
            );
          },
        ),
      );

  @override
  FutureResult<Debt> getDebt(String id) => _guard(() async {
        final row = await _local.getDebt(id);
        if (row == null) {
          return Left(NotFoundFailure('debt "$id" does not exist'));
        }
        return Right(DebtMapper.toEntity(row));
      });

  @override
  FutureResult<DebtBalance> getBalance(String debtId) => _guard(() async {
        final row = await _local.getDebt(debtId);
        if (row == null) {
          return Left(NotFoundFailure('debt "$debtId" does not exist'));
        }
        final debt = DebtMapper.toEntity(row);
        final entries = (await _local.getDebtEntries(debtId))
            .map(DebtEntryMapper.toEntity)
            .toList();
        final cashEvents = (await _local.getDebtCashEvents(debtId))
            .map(DebtCashEventMapper.toEntity)
            .toList();
        return Right(
          _calculator.calculate(
            debt: debt,
            entries: entries,
            cashEvents: cashEvents,
          ),
        );
      });

  @override
  FutureResult<DebtAccrualContext> getAccrualContext(String debtId) =>
      _guard(() async {
        final balanceResult = await getBalance(debtId);
        return balanceResult.fold<FutureResult<DebtAccrualContext>>(
          (failure) async => Left(failure),
          (balance) async {
            // getBalance already proved the debt is alive.
            final debt = DebtMapper.toEntity((await _local.getDebt(debtId))!);
            final lastAccrual = await _local.lastAccrualDate(debtId);
            return Right(
              DebtAccrualContext(
                debt: debt,
                rawOutstandingMinor: balance.rawOutstandingMinor,
                lastAccrualDate: lastAccrual,
              ),
            );
          },
        );
      });

  @override
  FutureResult<Debt> createDebt(DebtDraft draft) => _guard(() async {
        final now = DateTime.now();
        final row = await _local.insertDebt(
          DebtMapper.toInsertCompanion(draft, now: now),
        );
        return Right(DebtMapper.toEntity(row));
      });

  @override
  FutureResult<Debt> updateDebt(DebtDraft draft) => _guard(() async {
        final id = draft.id;
        if (id == null) {
          return const Left(
            ValidationFailure(
              'cannot update a debt without an id',
              field: DebtDraft.fieldId,
            ),
          );
        }
        final row = await _local.updateDebt(
          id,
          DebtMapper.toUpdateCompanion(draft, now: DateTime.now()),
        );
        if (row == null) {
          return Left(NotFoundFailure('debt "$id" does not exist'));
        }
        return Right(DebtMapper.toEntity(row));
      });

  @override
  FutureResult<Unit> deleteDebt(String id) => _guard(() async {
        final now = DateTime.now();
        final row = await _local.updateDebt(
          id,
          DebtMapper.softDeleteCompanion(now: now),
        );
        if (row == null) {
          return Left(NotFoundFailure('debt "$id" does not exist'));
        }
        // HU-05: the solo-deuda entries hide with the debt; the cash
        // Transactions are left untouched.
        await _local.setEntriesDeletedAt(
          id,
          deletedAt: now,
          updatedAt: now.millisecondsSinceEpoch,
        );
        return const Right(unit);
      });

  @override
  FutureResult<Unit> restoreDebt(String id) => _guard(() async {
        final now = DateTime.now();
        final row = await _local.restoreDebt(
          id,
          DebtMapper.restoreCompanion(now: now),
        );
        if (row == null) {
          return Left(NotFoundFailure('debt "$id" does not exist'));
        }
        await _local.setEntriesDeletedAt(
          id,
          deletedAt: null,
          updatedAt: now.millisecondsSinceEpoch,
        );
        return const Right(unit);
      });

  @override
  FutureResult<Unit> registerCashEvent({
    required String debtId,
    required String accountId,
    required int amountMinor,
    required TransactionType type,
    required String currency,
    required DateTime date,
    String? note,
    String? categoryId,
  }) =>
      _guard(() async {
        final now = DateTime.now();
        await _local.insertCashEvent(
          db.TransactionsCompanion.insert(
            accountId: accountId,
            categoryId: Value(categoryId),
            amountMinor: amountMinor,
            currency: currency,
            type: TransactionMapper.typeToDb(type),
            date: date,
            note: Value(note),
            source: const Value(db.TxSource.manual),
            debtId: Value(debtId),
            createdAt: Value(now),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
        return const Right(unit);
      });

  @override
  FutureResult<DebtEntry> addDebtEntry(DebtEntryDraft draft) =>
      _guard(() async {
        final row = await _local.insertEntry(
          DebtEntryMapper.toInsertCompanion(draft, now: DateTime.now()),
        );
        return Right(DebtEntryMapper.toEntity(row));
      });

  @override
  FutureResult<Unit> linkTransactionToDebt({
    required String transactionId,
    required String debtId,
  }) =>
      _guard(() async {
        final debt = await _local.getDebt(debtId);
        if (debt == null) {
          return Left(NotFoundFailure('debt "$debtId" does not exist'));
        }
        final now = DateTime.now();
        final linked = await _local.linkTransaction(
          transactionId,
          db.TransactionsCompanion(
            debtId: Value(debtId),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
        if (linked == null) {
          return Left(
            NotFoundFailure('transaction "$transactionId" does not exist'),
          );
        }
        return const Right(unit);
      });

  Map<String, List<DebtEntry>> _groupEntries(List<db.DebtEntry> rows) {
    final byDebt = <String, List<DebtEntry>>{};
    for (final row in rows) {
      (byDebt[row.debtId] ??= []).add(DebtEntryMapper.toEntity(row));
    }
    return byDebt;
  }

  Map<String, List<DebtCashEvent>> _groupCashEvents(
    List<db.Transaction> rows,
  ) {
    final byDebt = <String, List<DebtCashEvent>>{};
    for (final row in rows) {
      final debtId = row.debtId;
      if (debtId == null) continue;
      (byDebt[debtId] ??= []).add(DebtCashEventMapper.toEntity(row));
    }
    return byDebt;
  }

  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      return Left(
        DatabaseFailure('debts query failed', cause: e, stackTrace: st),
      );
    }
  }

  Stream<Result<T>> _guardStream<T>(Stream<Result<T>> source) =>
      source.transform(
        StreamTransformer<Result<T>, Result<T>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) => sink.add(
            Left(
              DatabaseFailure(
                'debts stream failed',
                cause: error,
                stackTrace: stackTrace,
              ),
            ),
          ),
        ),
      );

  /// Hand-rolled `combineLatest` (no rxdart dependency), same helper as
  /// `BudgetRepositoryImpl`: emits once every source has produced a value, then
  /// on every subsequent change to any of them.
  Stream<R> _combineLatest<R>(
    List<Stream<Object?>> streams,
    R Function(List<Object?>) combine,
  ) {
    final latest = List<Object?>.filled(streams.length, null);
    final seen = List<bool>.filled(streams.length, false);
    final subscriptions = <StreamSubscription<Object?>>[];
    late final StreamController<R> controller;
    var open = streams.length;

    controller = StreamController<R>(
      onListen: () {
        for (var i = 0; i < streams.length; i++) {
          final index = i;
          subscriptions.add(
            streams[index].listen(
              (value) {
                latest[index] = value;
                seen[index] = true;
                if (seen.every((element) => element)) {
                  controller.add(combine(List<Object?>.of(latest)));
                }
              },
              onError: controller.addError,
              onDone: () {
                open--;
                if (open == 0) {
                  unawaited(controller.close());
                }
              },
            ),
          );
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }
}
