import 'package:injectable/injectable.dart';

import '../entities/cloud_transcription_consent.dart';
import '../repositories/cloud_transcription_consent_store.dart';

/// Records the user's answer about transcribing their voice in the cloud.
///
/// Called from the sheet's two CTAs — which carry equal weight, so "Escribir a
/// mano" persists a refusal rather than leaving the question open and asking
/// again next time — and from the Ajustes switch, which is the reversal the
/// sheet promises in its caption.
@injectable
class SetCloudTranscriptionConsent {
  const SetCloudTranscriptionConsent(this._store);

  final CloudTranscriptionConsentStore _store;

  Future<void> call(CloudTranscriptionConsent consent) => _store.write(consent);

  /// Convenience for the Ajustes switch, which only ever moves between the two
  /// explicit answers — it can never put the decision back to "not asked".
  Future<void> setAllowed({required bool allowed}) => call(
        allowed
            ? CloudTranscriptionConsent.granted
            : CloudTranscriptionConsent.declined,
      );
}
