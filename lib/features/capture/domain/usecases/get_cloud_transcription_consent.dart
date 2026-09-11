import 'package:injectable/injectable.dart';

import '../entities/cloud_transcription_consent.dart';
import '../repositories/cloud_transcription_consent_store.dart';

/// Reads whether this device may send its audio out to be transcribed.
///
/// Read by the capture flow (to decide between listening with the cloud route
/// allowed, showing the sheet, or falling straight back to the manual form)
/// and by Ajustes (to render the switch). Both go through here so neither one
/// invents its own default.
@injectable
class GetCloudTranscriptionConsent {
  const GetCloudTranscriptionConsent(this._store);

  final CloudTranscriptionConsentStore _store;

  Future<CloudTranscriptionConsent> call() => _store.read();
}
