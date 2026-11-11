import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/capture_diagnostics.dart';
import '../../domain/entities/issuer_app.dart';
import '../../domain/entities/parsed_notification.dart';
import '../../domain/repositories/notification_capture_repository.dart';
import '../datasources/capture_method_channel_datasource.dart';
import '../models/capture_diagnostics_model.dart';
import '../models/native_capture_model.dart';

/// Method-channel implementation of [NotificationCaptureRepository].
///
/// Every platform error becomes a `Failure`: this feature is additive and must
/// never take the app down. If the native side is missing (a build without the
/// service, a non-Android platform) the app keeps working with the feature
/// simply off.
@LazySingleton(as: NotificationCaptureRepository)
class NotificationCaptureRepositoryImpl
    implements NotificationCaptureRepository {
  const NotificationCaptureRepositoryImpl(this._datasource);

  final CaptureMethodChannelDatasource _datasource;

  @override
  bool get isSupported => _datasource.isSupported;

  @override
  FutureResult<bool> isPermissionGranted() =>
      _guard(_datasource.isPermissionGranted);

  @override
  FutureResult<Unit> openPermissionSettings() => _guard(() async {
        await _datasource.openPermissionSettings();
        return unit;
      });

  @override
  FutureResult<Set<String>> getEnabledIssuers() => _guard(() async {
        final List<String> issuers = await _datasource.getEnabledIssuers();
        return issuers.toSet();
      });

  @override
  FutureResult<Unit> setEnabledIssuers(Set<String> issuerIds) =>
      _guard(() async {
        await _datasource.setEnabledIssuers(issuerIds.toList());
        return unit;
      });

  @override
  FutureResult<List<ParsedNotification>> drainPendingCaptures() =>
      _guard(() async {
        final List<Map<Object?, Object?>> raw =
            await _datasource.drainPendingCaptures();
        return <ParsedNotification>[
          for (final Map<Object?, Object?> entry in raw)
            if (NativeCaptureModel.fromMap(entry)
                case final ParsedNotification c)
              c,
        ];
      });

  /// Plain forward: the stream is created by the datasource and carries no
  /// platform failure of its own (the doorbell only says "drain now; the drain
  /// itself reports its errors").
  @override
  Stream<void> incomingCaptureEvents() => _datasource.incomingCaptures;

  @override
  FutureResult<List<IssuerApp>> getInstalledIssuerApps() => _guard(() async {
        final List<Map<Object?, Object?>> raw =
            await _datasource.getInstalledIssuerApps();
        return <IssuerApp>[
          for (final Map<Object?, Object?> entry in raw)
            if (NativeCaptureModel.issuerAppFromMap(entry)
                case final IssuerApp a)
              a,
        ];
      });

  @override
  FutureResult<CaptureDiagnostics> getDiagnostics() => _guard(() async {
        final Map<Object?, Object?> raw = await _datasource.getDiagnostics();
        return CaptureDiagnosticsModel.fromMap(raw);
      });

  @override
  FutureResult<Unit> requestIgnoreBatteryOptimizations() => _guard(() async {
        await _datasource.requestIgnoreBatteryOptimizations();
        return unit;
      });

  @override
  FutureResult<Unit> openAutostartSettings() => _guard(() async {
        await _datasource.openAutostartSettings();
        return unit;
      });

  /// Wraps a channel call. `PlatformException`/`MissingPluginException` are
  /// the expected failure modes and neither must ever surface as a crash.
  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on MissingPluginException catch (e, st) {
      return Left(
        UnexpectedFailure(
          'capture channel is not available on this platform',
          cause: e,
          stackTrace: st,
        ),
      );
    } on PlatformException catch (e, st) {
      return Left(
        UnexpectedFailure(
          'capture channel call failed',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Left(
        UnexpectedFailure(
          'unexpected error talking to the capture service',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
