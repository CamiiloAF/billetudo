import '../entities/cloud_transcription_consent.dart';

/// Where the answer to the cloud-transcription sheet is kept.
///
/// **Per device, never synced.** This is not a stylistic choice: the consent
/// names a specific third party — Google on Android, Apple on iOS — and it is
/// given because *this* phone cannot transcribe on its own. Syncing it would
/// carry a permission granted to Google over to an iPhone and hand the audio
/// to Apple without anyone having agreed to that, which is the exact silent
/// downgrade the sheet exists to prevent.
///
/// Same reasoning `AccountFilterPreferenceDatasource` records for device-scoped
/// state, applied to something that actually matters.
abstract class CloudTranscriptionConsentStore {
  Future<CloudTranscriptionConsent> read();

  Future<void> write(CloudTranscriptionConsent consent);
}
