import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the "¿Agregar a una cuenta?" toggle of the abono sheet
/// (Deudas HU-02) was last left on for a given debt, so reopening that debt's
/// sheet defaults to the choice the user tends to make for it.
///
/// The default is layered, most-specific first:
///  1. the per-debt choice, if the user has registered an abono for it before;
///  2. otherwise the global choice, the last toggle used on any debt;
///  3. otherwise `true` ("Sí"), the design's default (`xbsY3`).
///
/// Local, per-device (SharedPreferences), never synced — same reasoning as
/// `AccountFilterPreferenceDatasource`: which way a device's sheet opens is a
/// device habit, not debt data, so a signed-in user's devices never fight over
/// it.
@lazySingleton
class DebtPaymentTogglePreferenceDatasource {
  const DebtPaymentTogglePreferenceDatasource(this._prefs);

  static const String _globalKey = 'debt_payment_add_to_account';
  static const String _perDebtPrefix = 'debt_payment_add_to_account:';

  final SharedPreferencesAsync _prefs;

  /// Reads the remembered default for [debtId] following the layered fallback
  /// (per-debt → global → `true`).
  Future<bool> readAddToAccount(String debtId) async {
    final perDebt = await _prefs.getBool('$_perDebtPrefix$debtId');
    if (perDebt != null) {
      return perDebt;
    }
    final global = await _prefs.getBool(_globalKey);
    return global ?? true;
  }

  /// Persists the choice both against [debtId] and as the global fallback, so
  /// the next abono — on this debt or any other new one — opens the same way.
  Future<void> writeAddToAccount({
    required String debtId,
    required bool addToAccount,
  }) async {
    await _prefs.setBool('$_perDebtPrefix$debtId', addToAccount);
    await _prefs.setBool(_globalKey, addToAccount);
  }
}
