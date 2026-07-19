import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/result.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_detail_data.dart';
import '../../domain/entities/budget_draft.dart';
import '../../domain/entities/budget_expense.dart';
import '../../domain/entities/budget_scope.dart';
import '../../domain/entities/budget_with_progress.dart';
import '../../domain/entities/period_income.dart';
import '../../domain/entities/zero_based_summary.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/services/budget_period_calculator.dart';
import '../../domain/services/budget_progress_calculator.dart';
import '../../domain/services/zero_based_summary_calculator.dart';
import '../datasources/budgets_local_datasource.dart';
import '../models/budget_mapper.dart';

/// Drift implementation of [BudgetRepository].
///
/// Owns two cross-cutting rules: `updatedAt` is stamped on every write, and the
/// scope join rows are reconciled inside the same create/edit call. The progress
/// math is delegated to the domain calculators so there is a single
/// implementation of the global-vs-emptied and period rules.
@LazySingleton(as: BudgetRepository)
class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._local, this._progress, this._zeroBased);

  final BudgetsLocalDatasource _local;
  final BudgetProgressCalculator _progress;
  final ZeroBasedSummaryCalculator _zeroBased;

  @override
  Stream<Result<List<BudgetWithProgress>>> watchActiveBudgets() =>
      _watchListWithProgress(_local.watchActiveBudgets(), atClose: false);

  @override
  Stream<Result<List<BudgetWithProgress>>> watchArchivedBudgets() =>
      _watchListWithProgress(_local.watchArchivedBudgets(), atClose: true);

  /// Builds a progress list from a budgets stream, joined against the live
  /// scope, expenses and category tree. [atClose] picks the reference instant:
  /// the current period for active budgets, the period they were closed in for
  /// archived ones (HU-11).
  Stream<Result<List<BudgetWithProgress>>> _watchListWithProgress(
    Stream<List<db.Budget>> budgets, {
    required bool atClose,
  }) =>
      _guardStream(
        _combineLatest(
          [
            budgets,
            _local.watchScopeAccounts(),
            _local.watchScopeCategories(),
            _local.watchExpenses(),
            _local.watchAliveCategories(),
          ],
          (values) {
            final rows = values[0]! as List<db.Budget>;
            final accountScope = values[1]! as List<BudgetScopeRefRow>;
            final categoryScope = values[2]! as List<BudgetScopeRefRow>;
            final expenses = values[3]! as List<BudgetExpenseRow>;
            final categories = values[4]! as List<db.Category>;
            final children = _categoryChildren(categories);
            final now = DateTime.now();
            final domainExpenses = expenses.map(_toExpense).toList();

            return Right<Failure, List<BudgetWithProgress>>([
              for (final row in rows)
                _toWithProgress(
                  budget: BudgetMapper.toEntity(row),
                  accountScope: accountScope,
                  categoryScope: categoryScope,
                  expenses: domainExpenses,
                  children: children,
                  reference: atClose ? (row.archivedAt ?? now) : now,
                ),
            ]);
          },
        ),
      );

  BudgetWithProgress _toWithProgress({
    required Budget budget,
    required List<BudgetScopeRefRow> accountScope,
    required List<BudgetScopeRefRow> categoryScope,
    required List<BudgetExpense> expenses,
    required Map<String, List<String>> children,
    required DateTime reference,
  }) {
    final scope = _scopeFor(budget.id, accountScope, categoryScope);
    final window = BudgetPeriodCalculator(budget).currentWindow(reference);
    final progress = _progress.progressIn(
      budget: budget,
      scope: scope,
      window: window,
      expenses: expenses,
      now: reference,
      categoryChildren: children,
    );
    return BudgetWithProgress(
      budget: budget,
      scope: scope,
      window: window,
      progress: progress,
    );
  }

  @override
  Stream<Result<BudgetDetailData>> watchBudgetDetail(String id) => _guardStream(
        _combineLatest(
          [
            _local.watchBudget(id),
            _local.watchScopeAccounts(),
            _local.watchScopeCategories(),
            _local.watchExpenses(),
            _local.watchAliveCategories(),
          ],
          (values) {
            final row = values[0] as db.Budget?;
            if (row == null) {
              return Left<Failure, BudgetDetailData>(
                NotFoundFailure('budget "$id" does not exist'),
              );
            }
            final accountScope = values[1]! as List<BudgetScopeRefRow>;
            final categoryScope = values[2]! as List<BudgetScopeRefRow>;
            final expenses = values[3]! as List<BudgetExpenseRow>;
            final categories = values[4]! as List<db.Category>;

            return Right<Failure, BudgetDetailData>(
              BudgetDetailData(
                budget: BudgetMapper.toEntity(row),
                scope: _scopeFor(id, accountScope, categoryScope),
                expenses: [
                  for (final expense in expenses)
                    BudgetExpenseDetail(
                      expense: _toExpense(expense),
                      title: expense.categoryName ?? expense.accountName,
                      accountName: expense.accountName,
                      categoryIcon: expense.categoryIcon,
                      categoryColor: expense.categoryColor,
                      note: expense.note,
                    ),
                ],
                categoryChildren: _categoryChildren(categories),
              ),
            );
          },
        ),
      );

  @override
  Stream<Result<ZeroBasedSummary?>> watchZeroBasedSummary() => _guardStream(
        _combineLatest(
          [
            _local.watchActiveBudgets(),
            _local.watchIncome(),
          ],
          (values) {
            final budgets = values[0]! as List<db.Budget>;
            final income = values[1]! as List<BudgetIncomeRow>;
            return Right<Failure, ZeroBasedSummary?>(
              _zeroBased.summarize(
                activeBudgets: budgets.map(BudgetMapper.toEntity).toList(),
                income: [
                  for (final row in income)
                    PeriodIncome(
                      amountMinor: row.amountMinor,
                      currency: row.currency,
                      date: row.date,
                    ),
                ],
                now: DateTime.now(),
              ),
            );
          },
        ),
      );

  @override
  FutureResult<Budget> getBudget(String id) => _guard(() async {
        final row = await _local.getBudget(id);
        if (row == null) {
          return Left(NotFoundFailure('budget "$id" does not exist'));
        }
        return Right(BudgetMapper.toEntity(row));
      });

  @override
  FutureResult<Budget> createBudget(BudgetDraft draft) => _guard(() async {
        final now = DateTime.now();
        final row = await _local.insertBudget(
          BudgetMapper.toInsertCompanion(draft, now: now),
        );
        try {
          await _local.reconcileScope(
            row.id,
            accountIds: draft.accountIds,
            categoryIds: draft.categoryIds,
            now: now,
          );
        } catch (_) {
          // The budget the user asked for includes its scope; a half-written
          // one must not survive. The form has no id yet, so a second Save would
          // create a second budget instead of updating this one.
          await _local.hardDeleteBudget(row.id);
          rethrow;
        }
        return Right(BudgetMapper.toEntity(row));
      });

  @override
  FutureResult<Budget> updateBudget(BudgetDraft draft) => _guard(() async {
        final id = draft.id;
        if (id == null) {
          return const Left(
            ValidationFailure(
              'cannot update a budget without an id',
              field: BudgetDraft.fieldName,
            ),
          );
        }
        final now = DateTime.now();
        final row = await _local.updateBudget(
          id,
          BudgetMapper.toUpdateCompanion(draft, now: now),
        );
        if (row == null) {
          return Left(NotFoundFailure('budget "$id" does not exist'));
        }
        await _local.reconcileScope(
          id,
          accountIds: draft.accountIds,
          categoryIds: draft.categoryIds,
          now: now,
        );
        return Right(BudgetMapper.toEntity(row));
      });

  @override
  FutureResult<Unit> closeBudget(String id) =>
      _writeArchived(id, archivedAt: DateTime.now());

  @override
  FutureResult<Unit> reactivateBudget(String id) =>
      _writeArchived(id, archivedAt: null);

  FutureResult<Unit> _writeArchived(String id,
          {required DateTime? archivedAt}) =>
      _guard(() async {
        final row = await _local.updateBudget(
          id,
          BudgetMapper.archivedCompanion(
            archivedAt: archivedAt,
            now: DateTime.now(),
          ),
        );
        if (row == null) {
          return Left(NotFoundFailure('budget "$id" does not exist'));
        }
        return const Right(unit);
      });

  @override
  FutureResult<Unit> deleteBudget(String id) => _guard(() async {
        final row = await _local.updateBudget(
          id,
          BudgetMapper.deletedCompanion(now: DateTime.now()),
        );
        if (row == null) {
          return Left(NotFoundFailure('budget "$id" does not exist'));
        }
        return const Right(unit);
      });

  BudgetScope _scopeFor(
    String budgetId,
    List<BudgetScopeRefRow> accountScope,
    List<BudgetScopeRefRow> categoryScope,
  ) =>
      BudgetScope(
        accounts: [
          for (final row in accountScope)
            if (row.budgetId == budgetId)
              BudgetScopeRef(id: row.refId, referentAlive: row.referentAlive),
        ],
        categories: [
          for (final row in categoryScope)
            if (row.budgetId == budgetId)
              BudgetScopeRef(id: row.refId, referentAlive: row.referentAlive),
        ],
      );

  BudgetExpense _toExpense(BudgetExpenseRow row) => BudgetExpense(
        id: row.id,
        accountId: row.accountId,
        categoryId: row.categoryId,
        amountMinor: row.amountMinor,
        currency: row.currency,
        date: row.date,
      );

  Map<String, List<String>> _categoryChildren(List<db.Category> categories) {
    final children = <String, List<String>>{};
    for (final category in categories) {
      final parentId = category.parentId;
      if (parentId != null) {
        children.putIfAbsent(parentId, () => []).add(category.id);
      }
    }
    return children;
  }

  /// Emits a list of the latest value of every [streams] entry, once each has
  /// emitted at least once (combineLatest — no rxdart in the project). Single
  /// subscription: a fresh watcher per call, which is what the cubits want.
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

  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      return Left(
        DatabaseFailure('budgets query failed', cause: e, stackTrace: st),
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
                'budgets stream failed',
                cause: error,
                stackTrace: stackTrace,
              ),
            ),
          ),
        ),
      );
}
