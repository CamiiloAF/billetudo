import 'package:equatable/equatable.dart';

import '../../domain/entities/speech_recognition.dart';
import '../../domain/entities/spoken_transaction_draft.dart';

/// Which of the designed surfaces the capture sheet is showing.
enum VoiceCaptureStatus {
  /// Checking availability and permission. No microphone is open yet.
  preparing,

  /// `tN3NS`: the in-context explainer. Shown before the system dialog the
  /// first time and reused whenever the permission is missing — never a dead
  /// end, "Escribir a mano" always leaves.
  permissionNeeded,

  /// `f8OP8a` / `Z6imP`: the microphone is open. The two frames are the same
  /// surface; what differs is whether [VoiceCaptureState.transcript] is empty.
  listening,

  /// `lLKTv`: the session ended with something transcribed but no amount in
  /// it. Nothing is lost — the transcript still travels to the form as a note.
  noAmount,

  /// Not a designed frame: the recognizer, the app's locale or the on-device
  /// route is unavailable, so no session can start at all. Same two exits as
  /// [noAmount] minus the retry, since retrying would fail identically.
  unavailable,

  /// A usable draft is ready and the sheet is about to hand it back.
  completed,
}

/// Why [VoiceCaptureStatus.unavailable] was reached, so the sheet can pick
/// honest copy instead of one vague "algo salió mal".
enum VoiceCaptureUnavailableReason {
  /// No recognizer, or not for the app's language.
  recognizer,

  /// On-device recognition is not available here and the app refuses to
  /// silently route the audio through the vendor's cloud (HU-06).
  onDeviceUnavailable,

  /// The recognizer needs a network it does not have.
  network,

  /// Another app holds the microphone.
  busy,
}

/// State of one capture session.
///
/// [transcript] and [draft] live here and nowhere else: the cubit closes with
/// the sheet, so both die with it. Nothing in this feature writes either to
/// disk, to Drift or to the sync queue (HU-06, retención cero).
class VoiceCaptureState extends Equatable {
  const VoiceCaptureState({
    this.status = VoiceCaptureStatus.preparing,
    this.transcript = '',
    this.soundLevel = 0,
    this.draft,
    this.permission = MicrophonePermissionStatus.denied,
    this.unavailableReason,
  });

  final VoiceCaptureStatus status;

  /// What has been recognized so far, partial included. In memory only.
  final String transcript;

  /// Normalized 0..1 microphone level driving the wave bars. Not money.
  final double soundLevel;

  /// The parsed draft. Set on [VoiceCaptureStatus.noAmount] too — that state
  /// still carries everything that *was* understood.
  final SpokenTransactionDraft? draft;

  final MicrophonePermissionStatus permission;

  final VoiceCaptureUnavailableReason? unavailableReason;

  /// Whether the system dialog can still be shown, or only the app's settings
  /// screen can change the answer (HU-07).
  bool get isPermissionAskable =>
      permission == MicrophonePermissionStatus.denied;

  /// True while the recognizer has produced nothing yet, which is what tells
  /// the transcript box to show its example instead of live text.
  bool get hasTranscript => transcript.trim().isNotEmpty;

  VoiceCaptureState copyWith({
    VoiceCaptureStatus? status,
    String? transcript,
    double? soundLevel,
    SpokenTransactionDraft? draft,
    MicrophonePermissionStatus? permission,
    VoiceCaptureUnavailableReason? unavailableReason,
  }) =>
      VoiceCaptureState(
        status: status ?? this.status,
        transcript: transcript ?? this.transcript,
        soundLevel: soundLevel ?? this.soundLevel,
        draft: draft ?? this.draft,
        permission: permission ?? this.permission,
        unavailableReason: unavailableReason ?? this.unavailableReason,
      );

  @override
  List<Object?> get props => [
        status,
        transcript,
        soundLevel,
        draft,
        permission,
        unavailableReason,
      ];
}
