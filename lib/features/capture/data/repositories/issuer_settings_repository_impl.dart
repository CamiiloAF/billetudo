import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/issuer_catalog_entry.dart';
import '../../domain/repositories/issuer_settings_repository.dart';
import '../datasources/issuer_catalog.dart';
import '../datasources/issuer_settings_preference_datasource.dart';

/// Implementation of [IssuerSettingsRepository] over the bundled catalog plus
/// the per-device switches.
///
/// The catalog is the only source of listenable packages: a stored package
/// that is no longer in it (an issuer removed in an update) is simply not
/// returned, so it cannot keep being listened to by inertia.
@LazySingleton(as: IssuerSettingsRepository)
class IssuerSettingsRepositoryImpl implements IssuerSettingsRepository {
  const IssuerSettingsRepositoryImpl(this._prefs, this._crash);

  final IssuerSettingsPreferenceDatasource _prefs;
  final CrashReporter _crash;

  @override
  FutureResult<List<IssuerCatalogEntry>> getIssuerCatalog() => _guard(() async {
        final enabled = await _prefs.readEnabledPackages();
        return Right(
          [
            for (final issuer in launchIssuerCatalog)
              issuer.copyWith(enabled: enabled.contains(issuer.packageName)),
          ],
        );
      });

  /// `yield*` rather than an `await for` loop: a listener that unsubscribes
  /// while no change is in flight would leave an `await for` blocked forever,
  /// and its `cancel()` would never complete.
  @override
  Stream<Result<List<IssuerCatalogEntry>>> watchIssuerCatalog() async* {
    yield await getIssuerCatalog();
    yield* _prefs.changes.asyncMap((_) => getIssuerCatalog());
  }

  @override
  FutureResult<Unit> setIssuerEnabled({
    required String packageName,
    required bool enabled,
  }) =>
      _guard(() async {
        final known = launchIssuerCatalog
            .any((issuer) => issuer.packageName == packageName);
        if (!known) {
          // Enabling a package outside the curated catalog would silently
          // widen what the app listens to, which is exactly what a closed
          // catalog exists to prevent.
          return Left(
            ValidationFailure('"$packageName" is not a catalog issuer'),
          );
        }
        final current = {...await _prefs.readEnabledPackages()};
        if (enabled) {
          current.add(packageName);
        } else {
          current.remove(packageName);
        }
        await _prefs.writeEnabledPackages(current);
        return const Right(unit);
      });

  @override
  FutureResult<Unit> disableAllIssuers() => _guard(() async {
        await _prefs.writeEnabledPackages(const <String>{});
        return const Right(unit);
      });

  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'issuer settings');
      return Left(
        UnexpectedFailure('issuer settings failed', cause: e, stackTrace: st),
      );
    }
  }
}
