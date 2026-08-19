import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/result.dart';
import '../../../home/domain/entities/quick_access_item.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../datasources/app_settings_local_datasource.dart';

/// Drift implementation of [AppSettingsRepository] over the singleton row.
@LazySingleton(as: AppSettingsRepository)
class AppSettingsRepositoryImpl implements AppSettingsRepository {
  const AppSettingsRepositoryImpl(this._local);

  final AppSettingsLocalDatasource _local;

  @override
  Stream<Result<AppSettings>> watchSettings() => _local
      .watchSettings()
      .map<Result<AppSettings>>(
        (row) => Right<Failure, AppSettings>(_toEntity(row)),
      )
      .transform(_guardStream());

  @override
  FutureResult<AppSettings> getSettings() async {
    try {
      final row = await _local.readSettings();
      return Right(_toEntity(row));
    } catch (e, st) {
      return Left(
        DatabaseFailure('failed to read settings', cause: e, stackTrace: st),
      );
    }
  }

  @override
  FutureResult<Unit> setZeroBasedEnabled({required bool enabled}) async {
    try {
      await _local.setZeroBasedEnabled(
        zeroBasedEnabled: enabled,
        now: DateTime.now(),
      );
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure('failed to update settings', cause: e, stackTrace: st),
      );
    }
  }

  @override
  FutureResult<Unit> setFeaturedBudget({required String budgetId}) async {
    try {
      await _local.setFeaturedBudget(budgetId: budgetId, now: DateTime.now());
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure('failed to update settings', cause: e, stackTrace: st),
      );
    }
  }

  @override
  FutureResult<Unit> clearFeaturedBudget() async {
    try {
      await _local.clearFeaturedBudget(now: DateTime.now());
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure('failed to update settings', cause: e, stackTrace: st),
      );
    }
  }

  @override
  FutureResult<Unit> setQuickAccessOrder(List<QuickAccessItem> order) async {
    try {
      await _local.setQuickAccessOrder(order: order, now: DateTime.now());
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure('failed to update settings', cause: e, stackTrace: st),
      );
    }
  }

  @override
  FutureResult<Unit> markCategoriesSeeded() async {
    try {
      await _local.markCategoriesSeeded(now: DateTime.now());
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure('failed to update settings', cause: e, stackTrace: st),
      );
    }
  }

  @override
  FutureResult<Unit> markOnboardingCompleted() async {
    try {
      await _local.markOnboardingCompleted(now: DateTime.now());
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure('failed to update settings', cause: e, stackTrace: st),
      );
    }
  }

  AppSettings _toEntity(db.AppSetting? row) => row == null
      ? const AppSettings.defaults()
      : AppSettings(
          zeroBasedEnabled: row.zeroBasedEnabled,
          categoriesSeeded: row.categoriesSeeded,
          onboardingCompleted: row.onboardingCompleted,
          featuredBudgetId: row.featuredBudgetId,
          featuredBudgetMode: _toFeaturedBudgetMode(row.featuredBudgetMode),
          quickAccessOrder: _toQuickAccessOrder(row.quickAccessOrder),
        );

  /// Parses the persisted comma-separated `QuickAccessItem.name` list back
  /// into entities, falling back to [QuickAccessItem.defaultOrder] whenever
  /// the stored value is null/empty (predates the column, or was never set)
  /// or malformed (an unknown item name, or not an exact permutation of the
  /// 3 known items — a duplicate or a missing one). This is the single place
  /// that decides "trustworthy or not": nothing downstream (the cubit, the
  /// UI) ever has to re-validate.
  List<QuickAccessItem> _toQuickAccessOrder(String? raw) {
    if (raw == null || raw.isEmpty) {
      return QuickAccessItem.defaultOrder;
    }
    final items = <QuickAccessItem>[];
    for (final name in raw.split(',')) {
      QuickAccessItem? match;
      for (final item in QuickAccessItem.values) {
        if (item.name == name) {
          match = item;
          break;
        }
      }
      if (match == null) {
        return QuickAccessItem.defaultOrder;
      }
      items.add(match);
    }
    return QuickAccessItem.isValidOrder(items)
        ? items
        : QuickAccessItem.defaultOrder;
  }

  /// Maps the Drift `FeaturedBudgetMode` (row) to the pure domain copy
  /// (`FeaturedBudgetMode` in `domain/entities/app_settings.dart`) — the two
  /// enums are kept separate on purpose so `domain/` never depends on Drift,
  /// same convention as `AccountType`.
  ///
  /// `null` is treated as `automatic` **only here, in the read/mapping
  /// layer** — never written back to the row. The column is nullable (fix
  /// for decision #25, `docs/requirements/fase-1/05-auth-sync.md`): a device
  /// whose PowerSync store synced before this column existed can have a
  /// physical `NULL` even when the real server value is something else
  /// (e.g. `manual`) that just hasn't come down yet. `automatic` also
  /// happens to be the correct fallback for that transient state (it is the
  /// pre-existing behavior every installation had before this column
  /// existed), so treating `null` as `automatic` here is safe either way —
  /// the danger was only ever in *persisting* that assumption via a
  /// migration backfill.
  FeaturedBudgetMode _toFeaturedBudgetMode(db.FeaturedBudgetMode? mode) =>
      switch (mode) {
        db.FeaturedBudgetMode.automatic || null => FeaturedBudgetMode.automatic,
        db.FeaturedBudgetMode.manual => FeaturedBudgetMode.manual,
        db.FeaturedBudgetMode.none => FeaturedBudgetMode.none,
      };

  StreamTransformer<Result<AppSettings>, Result<AppSettings>> _guardStream() =>
      StreamTransformer<Result<AppSettings>, Result<AppSettings>>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
        handleError: (error, stackTrace, sink) => sink.add(
          Left(
            DatabaseFailure(
              'settings stream failed',
              cause: error,
              stackTrace: stackTrace,
            ),
          ),
        ),
      );
}
