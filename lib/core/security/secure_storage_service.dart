import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../error/result.dart';

/// Wrapper over [FlutterSecureStorage] that returns `FutureResult` instead of
/// throwing, to fit the app's error handling.
///
/// Actual backing: Keystore (Android) / Keychain (iOS), with
/// `first_unlock_this_device` accessibility (never backed up to iCloud) —
/// configured in `core/di/register_module.dart`. Use it for sensitive data
/// that is **not** synced to the cloud: e.g. the full account number
/// (Cuentas HU-03).
@lazySingleton
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  FutureResult<Unit> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return const Right(unit);
    } catch (e, st) {
      return Left(
        SecureStorageFailure(
          'could not write "$key"',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  FutureResult<String?> read(String key) async {
    try {
      return Right(await _storage.read(key: key));
    } catch (e, st) {
      return Left(
        SecureStorageFailure('could not read "$key"', cause: e, stackTrace: st),
      );
    }
  }

  FutureResult<Unit> delete(String key) async {
    try {
      await _storage.delete(key: key);
      return const Right(unit);
    } catch (e, st) {
      return Left(
        SecureStorageFailure(
          'could not delete "$key"',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
