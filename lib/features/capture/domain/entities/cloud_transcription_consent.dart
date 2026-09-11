/// The user's answer to "may this phone send your voice to Google/Apple so it
/// can be transcribed?" (`kJG43`).
///
/// Three states, not a bool, because "never asked" and "said no" must lead to
/// different behaviour: the first one earns the sheet, the second one must not
/// see it again. Collapsing them would either re-ask a person who already
/// declined or silently treat a refusal as consent.
enum CloudTranscriptionConsent {
  /// Never asked. The sheet is shown the first time on-device recognition
  /// turns out to be impossible — before anything leaves the phone.
  unset,

  /// Explicitly allowed. `StartVoiceCapture` may pass
  /// `allowCloudRecognition: true`.
  granted,

  /// Explicitly refused. Dictation stops offering itself on this device and
  /// falls back to the manual form, which is Nivel 0 and always available.
  /// Reversible from Ajustes — the sheet promises exactly that.
  declined;

  bool get isGranted => this == CloudTranscriptionConsent.granted;

  /// Whether the consent sheet still has a question to ask. A refusal is an
  /// answer: re-showing the sheet on every attempt would turn an informed
  /// choice into nagging.
  bool get isPending => this == CloudTranscriptionConsent.unset;
}
