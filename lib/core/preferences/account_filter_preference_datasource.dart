import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads/writes the account filter selected in Movimientos (HU-06a), to
/// local, per-device storage, so it survives closing and reopening the app.
///
/// Deliberately not part of `TransactionFilter`'s Drift-backed data (synced
/// via PowerSync): which accounts a device's list view is filtered to is a
/// device preference, not an account one — the same reasoning as
/// `ThemePreferenceDatasource`/`BalanceCarouselPreferenceDatasource`. So a
/// signed-in user's devices never fight over it.
@lazySingleton
class AccountFilterPreferenceDatasource {
  const AccountFilterPreferenceDatasource(this._prefs);

  static const String _key = 'movements_account_filter';

  final SharedPreferencesAsync _prefs;

  /// Defaults to no filter (empty set = "todas las cuentas", the
  /// inclusive-empty convention of `TransactionFilter`) when nothing has been
  /// saved yet.
  Future<Set<String>> readAccountIds() async =>
      (await _prefs.getStringList(_key))?.toSet() ?? const <String>{};

  /// Clears the saved key on "todas las cuentas" instead of storing an empty
  /// list, keeping the persisted state minimal.
  Future<void> writeAccountIds(Set<String> accountIds) => accountIds.isEmpty
      ? _prefs.remove(_key)
      : _prefs.setStringList(_key, accountIds.toList());
}
