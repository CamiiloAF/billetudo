import 'package:injectable/injectable.dart';

import '../entities/speech_recognition.dart';
import '../repositories/speech_recognizer.dart';

/// The live stream of partial results, sound level and end-of-session for the
/// listening UI (HU-03).
@injectable
class WatchVoiceCaptureUpdates {
  const WatchVoiceCaptureUpdates(this._recognizer);

  final SpeechRecognizer _recognizer;

  Stream<SpeechRecognitionUpdate> call() => _recognizer.updates;
}
