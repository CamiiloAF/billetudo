import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/result.dart';
import '../../../debts/data/models/debt_cash_event_mapper.dart';
import '../../../debts/data/models/debt_entry_mapper.dart';
import '../../../debts/data/models/debt_mapper.dart';
import '../../../debts/domain/entities/debt.dart';
import '../../../debts/domain/entities/debt_cash_event.dart';
import '../../../debts/domain/entities/debt_entry.dart';
import '../../../debts/domain/services/debt_balance_calculator.dart';
import '../../domain/entities/cashflow_point.dart';
import '../../domain/entities/cashflow_series.dart';
import '../../domain/entities/category_breakdown.dart';
import '../../domain/entities/category_breakdown_item.dart';
import '../../domain/entities/chart_history_bounds.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/entities/net_worth_point.dart';
import '../../domain/entities/net_worth_series.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/services/resolve_effective_date_range.dart';
import '../datasources/reports_local_datasource.dart';
import '../models/cashflow_row.dart';
import '../models/category_row.dart';
import '../models/net_worth_row.dart';

/// Drift implementation of [ReportsRepository].
///
/// Every requested [DateRange] is first resolved against the earliest date
/// with real data (HU-06, `ResolveEffectiveDateRange`) before any bucketed
/// query runs — the effective range/granularity that decision produces is
/// what actually gets queried, and it is echoed back on every series as
/// `ChartHistoryBounds` so the presentation layer can render the "historial
/// insuficiente" note instead of a silently shorter chart.
@LazySingleton(as: ReportsRepository)
class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl(
    this._local,
    this._resolveEffectiveDateRange,
    this._debtBalanceCalculator,
    this._crash,
  );

  final ReportsLocalDatasource _local;
  final ResolveEffectiveDateRange _resolveEffectiveDateRange;
  final DebtBalanceCalculator _debtBalanceCalculator;
  final CrashReporter _crash;

  // ---------------------------------------------------------------------
  // HU-01: flujo de caja
  // ---------------------------------------------------------------------

  @override
  Stream<Result<CashflowSeries>> watchCashflow({
    required DateRange range,
    required bool includeDebtMovements,
    required Set<String> accountIds,
  }) =>
      _guardStream(
        _switchLatest(_local.watchEarliestDataDate(), (earliestDataDate) {
          final bounds = _resolveEffectiveDateRange(
            requested: range,
            earliestDataDate: earliestDataDate,
          );
          final effective = bounds.effectiveRange;
          return _local
              .watchCashflowBuckets(
                start: effective.start,
                endExclusive: effective.endExclusive,
                granularity: effective.granularity,
                accountIds: accountIds,
              )
              .map(
                (rows) => Right<Failure, CashflowSeries>(
                  _buildCashflowSeries(rows, bounds, includeDebtMovements),
                ),
              );
        }),
      );

  CashflowSeries _buildCashflowSeries(
    List<CashflowRow> rows,
    ChartHistoryBounds bounds,
    bool includeDebtMovements,
  ) {
    final byKey = {for (final row in rows) row.bucketKey: row};
    final points = [
      for (final start in _bucketStarts(bounds.effectiveRange))
        () {
          final row =
              byKey[_formatBucketKey(start, bounds.effectiveRange.granularity)];
          return CashflowPoint(
            periodStart: start,
            incomeMinor: row?.incomeMinor ?? 0,
            expenseMinor: row?.expenseMinor ?? 0,
            debtIncomeMinor: row?.debtIncomeMinor ?? 0,
            debtExpenseMinor: row?.debtExpenseMinor ?? 0,
          );
        }(),
    ];
    return CashflowSeries(
      points: points,
      includeDebtMovements: includeDebtMovements,
      bounds: bounds,
    );
  }

  // ---------------------------------------------------------------------
  // HU-02: patrimonio
  // ---------------------------------------------------------------------

  @override
  Stream<Result<NetWorthSeries>> watchNetWorth({
    required DateRange range,
    required bool includeArchivedAccounts,
    required Set<String> accountIds,
  }) =>
      _guardStream(
        _switchLatest(_local.watchEarliestDataDate(), (earliestDataDate) {
          final bounds = _resolveEffectiveDateRange(
            requested: range,
            earliestDataDate: earliestDataDate,
          );
          final effective = bounds.effectiveRange;

          return _combineLatest<Result<NetWorthSeries>>(
            [
              _local.watchAccountsOpeningBalanceSum(
                includeArchived: includeArchivedAccounts,
                accountIds: accountIds,
              ),
              _local.watchOriginEffectBefore(
                effective.start,
                includeArchived: includeArchivedAccounts,
                accountIds: accountIds,
              ),
              _local.watchDestinationEffectBefore(
                effective.start,
                includeArchived: includeArchivedAccounts,
                accountIds: accountIds,
              ),
              _local.watchOriginEffectBuckets(
                start: effective.start,
                endExclusive: effective.endExclusive,
                granularity: effective.granularity,
                includeArchived: includeArchivedAccounts,
                accountIds: accountIds,
              ),
              _local.watchDestinationEffectBuckets(
                start: effective.start,
                endExclusive: effective.endExclusive,
                granularity: effective.granularity,
                includeArchived: includeArchivedAccounts,
                accountIds: accountIds,
              ),
              _local.watchAliveDebts(),
              _local.watchDebtEntriesBefore(effective.endExclusive),
              _local.watchDebtCashEventsBefore(effective.endExclusive),
            ],
            (values) {
              final openingSum = values[0]! as int;
              final originBefore = values[1]! as int;
              final destBefore = values[2]! as int;
              final originBuckets = values[3]! as List<AccountBalanceBucketRow>;
              final destBuckets = values[4]! as List<AccountBalanceBucketRow>;
              final debts = values[5]! as List<db.Debt>;
              final entries = values[6]! as List<db.DebtEntry>;
              final cashEvents = values[7]! as List<db.Transaction>;

              return Right<Failure, NetWorthSeries>(
                _buildNetWorthSeries(
                  bounds: bounds,
                  includeArchivedAccounts: includeArchivedAccounts,
                  liquidBaseline: openingSum + originBefore + destBefore,
                  originBuckets: originBuckets,
                  destBuckets: destBuckets,
                  debts: debts,
                  entries: entries,
                  cashEvents: cashEvents,
                ),
              );
            },
          );
        }),
      );

  NetWorthSeries _buildNetWorthSeries({
    required ChartHistoryBounds bounds,
    required bool includeArchivedAccounts,
    required int liquidBaseline,
    required List<AccountBalanceBucketRow> originBuckets,
    required List<AccountBalanceBucketRow> destBuckets,
    required List<db.Debt> debts,
    required List<db.DebtEntry> entries,
    required List<db.Transaction> cashEvents,
  }) {
    final effective = bounds.effectiveRange;
    final originByKey = {
      for (final row in originBuckets) row.bucketKey: row.deltaMinor
    };
    final destByKey = {
      for (final row in destBuckets) row.bucketKey: row.deltaMinor
    };

    final bucketStarts = _bucketStarts(effective);
    final boundaries = [...bucketStarts, effective.endExclusive];

    final domainDebts = debts.map(DebtMapper.toEntity).toList();
    final entriesByDebt = <String, List<DebtEntry>>{};
    for (final entry in entries.map(DebtEntryMapper.toEntity)) {
      entriesByDebt.putIfAbsent(entry.debtId, () => []).add(entry);
    }
    final cashEventsByDebt = <String, List<DebtCashEvent>>{};
    for (var i = 0; i < cashEvents.length; i++) {
      final row = cashEvents[i];
      final debtId = row.debtId;
      if (debtId == null) continue;
      cashEventsByDebt
          .putIfAbsent(debtId, () => [])
          .add(DebtCashEventMapper.toEntity(row));
    }

    var liquid = liquidBaseline;
    final points = <NetWorthPoint>[];
    for (var i = 0; i < boundaries.length; i++) {
      final cutoff = boundaries[i];
      if (i > 0) {
        final bucketStart = bucketStarts[i - 1];
        final key = _formatBucketKey(bucketStart, effective.granularity);
        liquid += (originByKey[key] ?? 0) + (destByKey[key] ?? 0);
      }
      final pending = _debtPendingAt(
        domainDebts,
        entriesByDebt,
        cashEventsByDebt,
        cutoff,
      );
      points.add(
        NetWorthPoint(
          date: cutoff,
          liquidMinor: liquid,
          totalMinor:
              liquid - pending.iOwePendingMinor + pending.owedToMePendingMinor,
        ),
      );
    }

    return NetWorthSeries(
      points: points,
      includeArchivedAccounts: includeArchivedAccounts,
      bounds: bounds,
    );
  }

  /// Σ pendiente `iOwe` and Σ pendiente `owedToMe` as of [cutoff], one
  /// `DebtBalanceCalculator.calculate` per debt still open at that point —
  /// reused verbatim so this never diverges from the debt detail screen's own
  /// outstanding-balance math (criterion 7).
  ({int iOwePendingMinor, int owedToMePendingMinor}) _debtPendingAt(
    List<Debt> debts,
    Map<String, List<DebtEntry>> entriesByDebt,
    Map<String, List<DebtCashEvent>> cashEventsByDebt,
    DateTime cutoff,
  ) {
    var iOwe = 0;
    var owedToMe = 0;
    for (final debt in debts) {
      if (!debt.effectiveStartDate.isBefore(cutoff)) continue;
      final entries = (entriesByDebt[debt.id] ?? const <DebtEntry>[])
          .where((entry) => entry.entryDate.isBefore(cutoff))
          .toList();
      final cashEvents = (cashEventsByDebt[debt.id] ?? const <DebtCashEvent>[])
          .where((event) => event.date.isBefore(cutoff))
          .toList();
      final balance = _debtBalanceCalculator.calculate(
        debt: debt,
        entries: entries,
        cashEvents: cashEvents,
      );
      switch (debt.direction) {
        case DebtDirection.iOwe:
          iOwe += balance.outstandingMinor;
        case DebtDirection.owedToMe:
          owedToMe += balance.outstandingMinor;
      }
    }
    return (iOwePendingMinor: iOwe, owedToMePendingMinor: owedToMe);
  }

  // ---------------------------------------------------------------------
  // HU-03: estructura de gasto
  // ---------------------------------------------------------------------

  @override
  Stream<Result<CategoryBreakdown>> watchCategoryBreakdown({
    required DateRange range,
    required Set<String> accountIds,
  }) =>
      _guardStream(
        _local
            .watchCategoryExpenseRows(
              start: range.start,
              endExclusive: range.endExclusive,
              accountIds: accountIds,
            )
            .asyncMap(
              (rows) async => Right<Failure, CategoryBreakdown>(
                  await _buildCategoryBreakdown(rows, range)),
            ),
      );

  Future<CategoryBreakdown> _buildCategoryBreakdown(
    List<CategoryExpenseRow> rows,
    DateRange range,
  ) async {
    final ids = [
      for (final row in rows)
        if (row.categoryId != null) row.categoryId!,
    ];
    final categories = await _local.getCategoriesByIds(ids);
    final categoryById = {
      for (final category in categories) category.id: category
    };

    // A root category with no expense rows of its own (only its
    // subcategories were spent against, e.g. because the active account
    // filter excludes the root's own direct movements) never enters `ids`
    // above, so it would otherwise resolve to a null name/icon. Backfill it
    // here from the parentId of whatever subcategories did resolve.
    final missingRootIds = {
      for (final category in categories)
        if (category.parentId != null &&
            !categoryById.containsKey(category.parentId))
          category.parentId!,
    };
    if (missingRootIds.isNotEmpty) {
      final missingRoots =
          await _local.getCategoriesByIds(missingRootIds.toList());
      for (final root in missingRoots) {
        categoryById[root.id] = root;
      }
    }

    final rootTotals = <String, int>{};
    final rootCounts = <String, int>{};
    final subtotalsByRoot = <String, Map<String, int>>{};
    final subcountsByRoot = <String, Map<String, int>>{};
    var uncategorizedMinor = 0;
    var uncategorizedCount = 0;
    var total = 0;

    for (final row in rows) {
      total += row.amountMinor;
      final categoryId = row.categoryId;
      if (categoryId == null) {
        uncategorizedMinor += row.amountMinor;
        uncategorizedCount += row.movementCount;
        continue;
      }
      final category = categoryById[categoryId];
      final rootId = category?.parentId ?? categoryId;
      rootTotals[rootId] = (rootTotals[rootId] ?? 0) + row.amountMinor;
      rootCounts[rootId] = (rootCounts[rootId] ?? 0) + row.movementCount;
      if (category?.parentId != null) {
        final subtotals = subtotalsByRoot.putIfAbsent(rootId, () => {});
        subtotals[categoryId] = (subtotals[categoryId] ?? 0) + row.amountMinor;
        final subcounts = subcountsByRoot.putIfAbsent(rootId, () => {});
        subcounts[categoryId] =
            (subcounts[categoryId] ?? 0) + row.movementCount;
      }
    }

    final items = <CategoryBreakdownItem>[
      for (final entry in rootTotals.entries)
        CategoryBreakdownItem(
          categoryId: entry.key,
          name: categoryById[entry.key]?.name,
          icon: categoryById[entry.key]?.icon,
          color: categoryById[entry.key]?.color,
          amountMinor: entry.value,
          movementCount: rootCounts[entry.key] ?? 0,
          subcategories: [
            for (final sub in (subtotalsByRoot[entry.key] ?? const {}).entries)
              CategoryBreakdownItem(
                categoryId: sub.key,
                name: categoryById[sub.key]?.name,
                icon: categoryById[sub.key]?.icon,
                color: categoryById[sub.key]?.color,
                amountMinor: sub.value,
                movementCount: subcountsByRoot[entry.key]?[sub.key] ?? 0,
              ),
          ]..sort((a, b) => b.amountMinor.compareTo(a.amountMinor)),
        ),
    ]..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));

    if (uncategorizedMinor > 0) {
      items.add(
        CategoryBreakdownItem(
          categoryId: null,
          name: null,
          amountMinor: uncategorizedMinor,
          movementCount: uncategorizedCount,
        ),
      );
    }

    return CategoryBreakdown(items: items, totalMinor: total, range: range);
  }

  // ---------------------------------------------------------------------
  // HU-06
  // ---------------------------------------------------------------------

  @override
  Stream<Result<DateTime?>> watchEarliestDataDate() =>
      _guardStream(_local.watchEarliestDataDate().map(Right.new));

  // ---------------------------------------------------------------------
  // Bucketing helpers
  // ---------------------------------------------------------------------

  /// Every bucket's start date within [range], truncated to the bucket's own
  /// granularity so it lines up with the `strftime`-derived keys the
  /// datasource groups by.
  List<DateTime> _bucketStarts(DateRange range) {
    final starts = <DateTime>[];
    var cursor = _truncate(range.start, range.granularity);
    while (cursor.isBefore(range.endExclusive)) {
      starts.add(cursor);
      cursor = range.granularity == DateGranularity.monthly
          ? DateTime(cursor.year, cursor.month + 1)
          : DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
    return starts;
  }

  DateTime _truncate(DateTime date, DateGranularity granularity) =>
      granularity == DateGranularity.monthly
          ? DateTime(date.year, date.month)
          : DateTime(date.year, date.month, date.day);

  String _formatBucketKey(DateTime date, DateGranularity granularity) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    if (granularity == DateGranularity.monthly) return '$year-$month';
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // ---------------------------------------------------------------------
  // Stream plumbing (same hand-rolled helpers as
  // `GoalRepositoryImpl`/`DebtRepositoryImpl`/`BudgetRepositoryImpl` — no
  // rxdart dependency in this project).
  // ---------------------------------------------------------------------

  Stream<Result<T>> _guardStream<T>(Stream<Result<T>> source) =>
      source.transform(
        StreamTransformer<Result<T>, Result<T>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            unawaited(
              _crash.recordError(error, stackTrace, context: 'reports stream'),
            );
            sink.add(
              Left(
                DatabaseFailure(
                  'reports stream failed',
                  cause: error,
                  stackTrace: stackTrace,
                ),
              ),
            );
          },
        ),
      );

  /// Switches to a brand-new inner stream (cancelling the previous one)
  /// every time [source] emits — a minimal "switchMap" for the rare case
  /// where the earliest-data date itself changes mid-subscription.
  Stream<R> _switchLatest<E, R>(
    Stream<E> source,
    Stream<R> Function(E event) mapper,
  ) {
    late final StreamController<R> controller;
    StreamSubscription<E>? outerSubscription;
    StreamSubscription<R>? innerSubscription;

    controller = StreamController<R>(
      onListen: () {
        outerSubscription = source.listen(
          (event) {
            unawaited(innerSubscription?.cancel());
            innerSubscription = mapper(event).listen(
              controller.add,
              onError: controller.addError,
            );
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () async {
        await innerSubscription?.cancel();
        await outerSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  /// Hand-rolled `combineLatest` (no rxdart dependency), same helper as
  /// `GoalRepositoryImpl`/`DebtRepositoryImpl`/`BudgetRepositoryImpl`.
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
