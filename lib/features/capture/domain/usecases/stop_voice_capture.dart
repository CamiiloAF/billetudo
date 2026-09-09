import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/speech_recognizer.dart';

/// Ends the listening session and keeps what was recognized (HU-03).
@injectable
class StopVoiceCapture {
  const StopVoiceCapture(this._recognizer);

  final SpeechRecognizer _recognizer;

  FutureResult<Unit> call() => _recognizer.stop();
}
