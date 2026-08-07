import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/result.dart';
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
        );

  /// Maps the Drift `FeaturedBudgetMode` (row) to the pure domain copy
  /// (`FeaturedBudgetMode` in `domain/entities/app_settings.dart`) — the two
  /// enums are kept separate on purpose so `domain/` never depends on Drift,
  /// same convention as `AccountType`.
  FeaturedBudgetMode _toFeaturedBudgetMode(db.FeaturedBudgetMode mode) =>
      switch (mode) {
        db.FeaturedBudgetMode.automatic => FeaturedBudgetMode.automatic,
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
