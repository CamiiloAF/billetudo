import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/security/secure_storage_service.dart';

/// The only place in the app that touches a full account number (HU-03).
///
/// The number lives exclusively in the device's Keychain/Keystore, keyed by the
/// account id. It is never written to Drift (`accountNumberEnc` stays NULL) and
/// therefore never reaches Supabase/PowerSync: changing devices means typing it
/// again, which is the intended trade-off.
@lazySingleton
class AccountNumberLocalDatasource {
  const AccountNumberLocalDatasource(this._storage);

  static const String keyPrefix = 'account_number_';

  final SecureStorageService _storage;

  /// Key derived from the account id, so each account owns its own entry.
  static String keyFor(String accountId) => '$keyPrefix$accountId';

  FutureResult<String?> read(String accountId) =>
      _storage.read(keyFor(accountId));

  /// Writes the number. Erasing it is [delete] and nothing else: [number] is
  /// non-nullable so that no absent value can ever be mistaken for "erase it".
  FutureResult<Unit> write(String accountId, String number) =>
      _storage.write(keyFor(accountId), number);

  FutureResult<Unit> delete(String accountId) =>
      _storage.delete(keyFor(accountId));
}
