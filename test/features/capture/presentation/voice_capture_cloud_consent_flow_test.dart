import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/capture/domain/entities/cloud_transcription_consent.dart';
import 'package:billetudo/features/capture/domain/entities/speech_recognition.dart';
import 'package:billetudo/features/capture/domain/usecases/cancel_voice_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/get_cloud_transcription_consent.dart';
import 'package:billetudo/features/capture/domain/usecases/get_voice_capture_availability.dart';
import 'package:billetudo/features/capture/domain/usecases/open_microphone_settings.dart';
import 'package:billetudo/features/capture/domain/usecases/parse_spoken_transaction.dart';
import 'package:billetudo/features/capture/domain/usecases/request_microphone_permission.dart';
import 'package:billetudo/features/capture/domain/usecases/set_cloud_transcription_consent.dart';
import 'package:billetudo/features/capture/domain/usecases/start_voice_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/stop_voice_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/watch_voice_capture_updates.dart';
import 'package:billetudo/features/capture/presentation/cubit/voice_capture_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/voice_capture_state.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/usecases/watch_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fake_cloud_transcription_consent_store.dart';
import '../fake_speech_recognizer.dart';

class _MockWatchAccounts extends Mock implements WatchAccounts {}

class _MockWatchCategories extends Mock implements WatchCategories {}

/// The cloud-transcription consent flow (`kJG43`).
///
/// The invariant under test is one sentence: **the audio never leaves the
/// phone unless this device's owner said it could.** Everything below is a
/// way for that to fail silently.
void main() {
  late FakeSpeechRecognizer recognizer;
  late FakeMicrophonePermissionGate gate;
  late FakeCloudTranscriptionConsentStore consentStore;
  late _MockWatchAccounts watchAccounts;
  late _MockWatchCategories watchCategories;

  VoiceCaptureCubit buildCubit() => VoiceCaptureCubit(
        GetVoiceCaptureAvailability(recognizer, gate),
        RequestMicrophonePermission(gate),
        OpenMicrophoneSettings(gate),
        StartVoiceCapture(recognizer, gate),
        StopVoiceCapture(recognizer),
        CancelVoiceCapture(recognizer),
        WatchVoiceCaptureUpdates(recognizer),
        const ParseSpokenTransaction(),
        watchAccounts,
        watchCategories,
        GetCloudTranscriptionConsent(consentStore),
        SetCloudTranscriptionConsent(consentStore),
      );

  Future<void> startAndSettle(VoiceCaptureCubit cubit) async {
    await cubit.start(localeId: 'es_CO', languageCode: 'es');
    await Future<void>.delayed(Duration.zero);
  }

  /// What the platform reports when the offline language pack is missing —
  /// the situation this whole surface exists for.
  void emitOnDeviceUnavailable() => recognizer.controller.add(
        const SpeechRecognitionUpdate(
          phase: SpeechRecognitionPhase.error,
          error: SpeechRecognitionErrorKind.onDeviceUnavailable,
        ),
      );

  setUpAll(() => registerFallbackValue(CategoryKind.expense));

  setUp(() {
    recognizer = FakeSpeechRecognizer();
    gate = FakeMicrophonePermissionGate();
    consentStore = FakeCloudTranscriptionConsentStore();
    watchAccounts = _MockWatchAccounts();
    watchCategories = _MockWatchCategories();
    when(watchAccounts.call).thenAnswer((_) => Stream.value(const Right([])));
    when(() => watchCategories(any()))
        .thenAnswer((_) => Stream.value(const Right([])));
  });

  test('a session never asks for the cloud route before being allowed to',
      () async {
    final cubit = buildCubit();
    await startAndSettle(cubit);

    expect(recognizer.lastAllowCloudRecognition, isFalse);
    await cubit.close();
  });

  test('an unset consent + no on-device route opens the sheet, sends nothing',
      () async {
    final cubit = buildCubit();
    await startAndSettle(cubit);
    emitOnDeviceUnavailable();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, VoiceCaptureStatus.cloudConsentNeeded);
    // The failed on-device attempt is the only thing that happened: nothing
    // was retried through the vendor while the question was still open.
    expect(recognizer.startCalls, 1);
    expect(recognizer.lastAllowCloudRecognition, isFalse);
    expect(consentStore.writes, isEmpty);
    await cubit.close();
  });

  test('"Permitir y dictar" persists the consent and re-listens with it',
      () async {
    final cubit = buildCubit();
    await startAndSettle(cubit);
    emitOnDeviceUnavailable();
    await Future<void>.delayed(Duration.zero);

    await cubit.allowCloudTranscription();
    await Future<void>.delayed(Duration.zero);

    expect(consentStore.consent, CloudTranscriptionConsent.granted);
    expect(recognizer.startCalls, 2);
    expect(recognizer.lastAllowCloudRecognition, isTrue);
    expect(cubit.state.status, VoiceCaptureStatus.listening);
    await cubit.close();
  });

  test('"Escribir a mano" records a refusal instead of leaving it open',
      () async {
    final cubit = buildCubit();
    await startAndSettle(cubit);
    emitOnDeviceUnavailable();
    await Future<void>.delayed(Duration.zero);

    await cubit.declineCloudTranscription();

    expect(consentStore.consent, CloudTranscriptionConsent.declined);
    await cubit.close();
  });

  test('a granted consent is honoured from the first attempt of a new session',
      () async {
    consentStore.consent = CloudTranscriptionConsent.granted;
    final cubit = buildCubit();
    await startAndSettle(cubit);

    expect(recognizer.lastAllowCloudRecognition, isTrue);
    await cubit.close();
  });

  test('a refusal is not re-litigated: no sheet, a way out, and no audio sent',
      () async {
    consentStore.consent = CloudTranscriptionConsent.declined;
    final cubit = buildCubit();
    await startAndSettle(cubit);
    expect(recognizer.lastAllowCloudRecognition, isFalse);

    emitOnDeviceUnavailable();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, VoiceCaptureStatus.unavailable);
    expect(
      cubit.state.unavailableReason,
      VoiceCaptureUnavailableReason.cloudConsentDeclined,
    );
    expect(cubit.state.status, isNot(VoiceCaptureStatus.cloudConsentNeeded));
    // Answering once must not cost a second answer.
    expect(consentStore.writes, isEmpty);
    await cubit.close();
  });
}
