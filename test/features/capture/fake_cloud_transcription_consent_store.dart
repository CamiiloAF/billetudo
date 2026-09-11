import 'package:billetudo/features/capture/domain/entities/cloud_transcription_consent.dart';
import 'package:billetudo/features/capture/domain/repositories/cloud_transcription_consent_store.dart';

/// In-memory [CloudTranscriptionConsentStore] for tests.
///
/// A fake rather than a mock because the interesting assertions are about
/// *what got persisted* ("Escribir a mano" must record a refusal, not just
/// close the sheet), and a real round-trip states that more plainly than a
/// verified call.
class FakeCloudTranscriptionConsentStore
    implements CloudTranscriptionConsentStore {
  FakeCloudTranscriptionConsentStore([
    this.consent = CloudTranscriptionConsent.unset,
  ]);

  CloudTranscriptionConsent consent;

  /// Every value written, in order, so a test can tell "written once" apart
  /// from "written twice with the same value".
  final List<CloudTranscriptionConsent> writes = <CloudTranscriptionConsent>[];

  @override
  Future<CloudTranscriptionConsent> read() async => consent;

  @override
  Future<void> write(CloudTranscriptionConsent consent) async {
    this.consent = consent;
    writes.add(consent);
  }
}
