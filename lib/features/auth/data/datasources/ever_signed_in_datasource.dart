import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, per device, whether this device has ever completed a
/// successful sign-in — even after `AuthRepositoryImpl.signOut` clears the
/// live session.
///
/// Exists for HU-07 "Eliminar cuenta": a signed-out device with no cloud
/// account (never signed in) and a signed-out device that *used to* have one
/// (signed out after signing in) must be told apart, so the flow never claims
/// a cloud account was deleted when it was only skipped because there was no
/// session to call the Edge Function with. [markSignedIn] is never undone by
/// [clear] on its own — only `AuthRepositoryImpl.deleteAccount` clears it,
/// once the cloud account really is gone.
///
/// Local, per-device (`SharedPreferences`), never synced — same pattern as
/// `ThemePreferenceDatasource`.
@lazySingleton
class EverSignedInDatasource {
  const EverSignedInDatasource(this._prefs);

  static const String _key = 'auth_ever_signed_in';

  final SharedPreferencesAsync _prefs;

  /// Defaults to `false` when nothing has been saved yet (a device that has
  /// never completed a sign-in).
  Future<bool> read() async => (await _prefs.getBool(_key)) ?? false;

  /// Marks this device as having signed in at least once. Idempotent; safe to
  /// call on every successful sign-in, not only the first.
  Future<void> markSignedIn() => _prefs.setBool(_key, true);

  /// Clears the flag. Only meant to run once the cloud account this device
  /// signed into has actually been deleted in Supabase — never on
  /// `AuthRepositoryImpl.signOut`.
  Future<void> clear() => _prefs.remove(_key);
}
