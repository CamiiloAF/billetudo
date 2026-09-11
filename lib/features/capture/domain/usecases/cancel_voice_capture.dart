import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/speech_recognizer.dart';

/// Aborts the listening session and discards audio and transcription (HU-03).
/// Nothing survives a cancel: no form opens and no row is written.
@injectable
class CancelVoiceCapture {
  const CancelVoiceCapture(this._recognizer);

  final SpeechRecognizer _recognizer;

  FutureResult<Unit> call() => _recognizer.cancel();
}
