import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/cloud_transcription_consent.dart';
import '../../domain/repositories/cloud_transcription_consent_store.dart';

/// `shared_preferences` implementation of [CloudTranscriptionConsentStore] —
/// the project's channel for per-device state, and the right one here for the
/// reason the interface documents.
///
/// The value is stored as the enum's `name` rather than a bool so that
/// "never asked" survives a restart as itself. A missing key is
/// [CloudTranscriptionConsent.unset]: absence of an answer is not a "no", and
/// it is certainly not a "yes".
@LazySingleton(as: CloudTranscriptionConsentStore)
class PreferencesCloudTranscriptionConsentStore
    implements CloudTranscriptionConsentStore {
  const PreferencesCloudTranscriptionConsentStore(this._prefs);

  static const String _key = 'capture_cloud_transcription_consent';

  final SharedPreferencesAsync _prefs;

  @override
  Future<CloudTranscriptionConsent> read() async {
    final stored = await _prefs.getString(_key);
    for (final value in CloudTranscriptionConsent.values) {
      if (value.name == stored) {
        return value;
      }
    }
    // Unknown or missing: fail closed. Nothing leaves the phone on the
    // strength of a value this build cannot read.
    return CloudTranscriptionConsent.unset;
  }

  @override
  Future<void> write(CloudTranscriptionConsent consent) =>
      _prefs.setString(_key, consent.name);
}
