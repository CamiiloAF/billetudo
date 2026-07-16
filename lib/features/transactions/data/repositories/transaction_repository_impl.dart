import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_draft.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_with_details.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/tags_local_datasource.dart';
import '../datasources/transactions_local_datasource.dart';
import '../models/tag_mapper.dart';
import '../models/transaction_mapper.dart';

/// Drift implementation of [TransactionRepository].
///
/// Owns the cross-cutting rule that `updatedAt` is stamped on **every**
/// write (via the mapper's companions), and that deletion is the reversible
/// UX trash (`deletedAt`, HU-05) — never `tombstonedAt`, since nothing in this
/// schema references a transaction's id by foreign key.
@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._local, this._tags);

  final TransactionsLocalDatasource _local;
  final TagsLocalDatasource _tags;

  @override
  Stream<Result<List<TransactionWithDetails>>> watchTransactions(
    TransactionFilter filter,
  ) =>
      _guardStream(
        _local
            .watchTransactions(
              accountIds: filter.accountIds,
              categoryIds: filter.categoryIds,
              types: filter.types.map(TransactionMapper.typeToDb).toSet(),
              tagIds: filter.tagIds,
              searchText: filter.searchText,
              periodStart: filter.datePeriod.start,
              periodEndExclusive: filter.datePeriod.endExclusive,
              orderBy: switch (filter.sortOrder) {
                TransactionSortOrder.dateDesc => TransactionOrderBy.dateDesc,
                TransactionSortOrder.amountDesc =>
                  TransactionOrderBy.amountDesc,
              },
            )
            .map((rows) => Right(rows.map(_toWithDetails).toList())),
      );

  @override
  Stream<Result<TransactionWithDetails>> watchTransactionDetail(String id) =>
      _guardStream(
        _local.watchTransactionDetail(id).map((rows) {
          if (rows.isEmpty) {
            return Left(NotFoundFailure('transaction "$id" does not exist'));
          }
          return Right(_toWithDetails(rows.first));
        }),
      );

  @override
  FutureResult<Transaction> getTransaction(String id) => _guard(() async {
        final row = await _local.getTransaction(id);
        if (row == null) {
          return Left(NotFoundFailure('transaction "$id" does not exist'));
        }
        return Right(TransactionMapper.toEntity(row));
      });

  @override
  FutureResult<Transaction> createTransaction(TransactionDraft draft) =>
      _guard(() async {
        final now = DateTime.now();
        final row = await _local.insertTransaction(
          TransactionMapper.toInsertCompanion(draft, now: now),
        );
        return Right(TransactionMapper.toEntity(row));
      });

  @override
  FutureResult<Transaction> updateTransaction(TransactionDraft draft) =>
      _guard(() async {
        final id = draft.id;
        if (id == null) {
          return const Left(
            ValidationFailure(
              'cannot update a transaction without an id',
              field: TransactionDraft.fieldId,
            ),
          );
        }

        final row = await _local.updateTransaction(
          id,
          TransactionMapper.toUpdateCompanion(draft, now: DateTime.now()),
        );
        if (row == null) {
          return Left(NotFoundFailure('transaction "$id" does not exist'));
        }
        return Right(TransactionMapper.toEntity(row));
      });

  /// HU-05: papelera/undo, via `deletedAt`.
  @override
  FutureResult<Unit> deleteTransaction(String id) => _guard(() async {
        final row = await _local.updateTransaction(
          id,
          TransactionMapper.softDeleteCompanion(now: DateTime.now()),
        );
        if (row == null) {
          return Left(NotFoundFailure('transaction "$id" does not exist'));
        }
        return const Right(unit);
      });

  /// HU-05: undo from the snackbar.
  @override
  FutureResult<Unit> restoreTransaction(String id) => _guard(() async {
        final row = await _local.restoreTransaction(
          id,
          TransactionMapper.restoreCompanion(now: DateTime.now()),
        );
        if (row == null) {
          return Left(NotFoundFailure('transaction "$id" does not exist'));
        }
        return const Right(unit);
      });

  @override
  FutureResult<Unit> setTransactionTags(
    String transactionId,
    List<String> tagIds,
  ) =>
      _guard(() async {
        final transaction = await _local.getTransaction(transactionId);
        if (transaction == null) {
          return Left(
            NotFoundFailure('transaction "$transactionId" does not exist'),
          );
        }
        await _tags.replaceTags(transactionId, tagIds, DateTime.now());
        return const Right(unit);
      });

  TransactionWithDetails _toWithDetails(TransactionRowWithJoins row) =>
      TransactionWithDetails(
        transaction: TransactionMapper.toEntity(row.transaction),
        accountName: row.account.name,
        transferAccountName: row.transferAccount?.name,
        categoryName: row.category?.name,
        categoryIcon: row.category?.icon,
        categoryColor: row.category?.color,
        tags: row.tags.map(TagMapper.toEntity).toList(),
      );

  /// Turns any infrastructure exception into a `Failure`, so nothing escapes
  /// the data layer as a raw exception.
  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'transactions query failed',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Same for streams: a query error becomes a `Left` **emission** instead of
  /// a stream error, so the cubit can render the error state without the
  /// subscription dying.
  Stream<Result<T>> _guardStream<T>(Stream<Result<T>> source) =>
      source.transform(
        StreamTransformer<Result<T>, Result<T>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) => sink.add(
            Left(
              DatabaseFailure(
                'transactions stream failed',
                cause: error,
                stackTrace: stackTrace,
              ),
            ),
          ),
        ),
      );
}
