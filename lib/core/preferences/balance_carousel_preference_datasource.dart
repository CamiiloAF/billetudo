import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads/writes whether the Movimientos balance carousel is collapsed
/// (Mejora #2), to local, per-device storage.
///
/// Deliberately not part of `AppSettings` (Drift, synced via PowerSync): the
/// collapsed/expanded state of a UI section is a device preference, not an
/// account one — the same reasoning as `ThemePreferenceDatasource`. So a
/// signed-in user's devices never fight over it. Backed by
/// `shared_preferences`, the project's channel for per-device UI preferences.
@lazySingleton
class BalanceCarouselPreferenceDatasource {
  const BalanceCarouselPreferenceDatasource(this._prefs);

  static const String _key = 'movements_balance_carousel_collapsed';

  final SharedPreferencesAsync _prefs;

  /// Defaults to expanded (`false`) when nothing has been saved yet — the
  /// approved design opens the carousel expanded on first launch.
  Future<bool> readCollapsed() async =>
      await _prefs.getBool(_key) ?? false;

  Future<void> writeCollapsed({required bool collapsed}) =>
      _prefs.setBool(_key, collapsed);
}
