import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/speech_recognition.dart';
import 'package:billetudo/features/capture/domain/repositories/microphone_permission_gate.dart';
import 'package:billetudo/features/capture/domain/repositories/speech_recognizer.dart';

/// In-memory recognizer, so nothing above `data` ever needs a microphone
/// (HU-10). Records what it was asked for, to assert the on-device request.
class FakeSpeechRecognizer implements SpeechRecognizer {
  FakeSpeechRecognizer({
    this.availability = const SpeechRecognizerAvailability(
      isAvailable: true,
      isLocaleSupported: true,
      route: SpeechRecognitionRoute.onDevice,
    ),
    this.prepareFailure,
  });

  SpeechRecognizerAvailability availability;
  Failure? prepareFailure;

  // ignore: close_sinks
  final StreamController<SpeechRecognitionUpdate> controller =
      StreamController<SpeechRecognitionUpdate>.broadcast();

  int startCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;
  bool? lastAllowCloudRecognition;
  String? lastLocaleId;
  Duration? lastMaxDuration;
  bool _listening = false;

  @override
  Stream<SpeechRecognitionUpdate> get updates => controller.stream;

  @override
  bool get isListening => _listening;

  @override
  Future<Result<SpeechRecognizerAvailability>> prepare({
    required String localeId,
  }) async {
    final failure = prepareFailure;
    return failure != null ? Left(failure) : Right(availability);
  }

  @override
  Future<Result<Unit>> start({
    required String localeId,
    bool allowCloudRecognition = false,
    Duration maxDuration = VoiceCaptureLimits.maxListenDuration,
    Duration pauseFor = VoiceCaptureLimits.pauseForSilence,
  }) async {
    startCalls++;
    lastLocaleId = localeId;
    lastAllowCloudRecognition = allowCloudRecognition;
    lastMaxDuration = maxDuration;
    _listening = true;
    return const Right(unit);
  }

  @override
  Future<Result<Unit>> stop() async {
    stopCalls++;
    _listening = false;
    return const Right(unit);
  }

  @override
  Future<Result<Unit>> cancel() async {
    cancelCalls++;
    _listening = false;
    return const Right(unit);
  }
}

/// Scriptable microphone gate.
class FakeMicrophonePermissionGate implements MicrophonePermissionGate {
  FakeMicrophonePermissionGate({
    this.status = MicrophonePermissionStatus.granted,
    this.statusAfterRequest,
  });

  MicrophonePermissionStatus status;
  MicrophonePermissionStatus? statusAfterRequest;

  int requestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<MicrophonePermissionStatus> current() async => status;

  @override
  Future<MicrophonePermissionStatus> request() async {
    requestCalls++;
    status = statusAfterRequest ?? status;
    return status;
  }

  @override
  Future<bool> openSystemSettings() async {
    openSettingsCalls++;
    return true;
  }
}
