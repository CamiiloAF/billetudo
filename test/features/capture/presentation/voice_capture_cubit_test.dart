import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/capture/domain/entities/speech_recognition.dart';
import 'package:billetudo/features/capture/domain/usecases/cancel_voice_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/get_voice_capture_availability.dart';
import 'package:billetudo/features/capture/domain/usecases/open_microphone_settings.dart';
import 'package:billetudo/features/capture/domain/usecases/parse_spoken_transaction.dart';
import 'package:billetudo/features/capture/domain/usecases/request_microphone_permission.dart';
import 'package:billetudo/features/capture/domain/usecases/start_voice_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/stop_voice_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/watch_voice_capture_updates.dart';
import 'package:billetudo/features/capture/presentation/cubit/voice_capture_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/voice_capture_state.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/domain/usecases/watch_categories.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../capture_fixtures.dart';
import '../fake_speech_recognizer.dart';

class _MockWatchAccounts extends Mock implements WatchAccounts {}

class _MockWatchCategories extends Mock implements WatchCategories {}

void main() {
  late FakeSpeechRecognizer recognizer;
  late FakeMicrophonePermissionGate gate;
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
      );

  Future<void> startAndSettle(VoiceCaptureCubit cubit) async {
    await cubit.start(localeId: 'es_CO', languageCode: 'es');
    await Future<void>.delayed(Duration.zero);
  }

  setUpAll(() => registerFallbackValue(CategoryKind.expense));

  setUp(() {
    recognizer = FakeSpeechRecognizer();
    gate = FakeMicrophonePermissionGate();
    watchAccounts = _MockWatchAccounts();
    watchCategories = _MockWatchCategories();
    when(watchAccounts.call).thenAnswer(
      (_) => Stream.value(
        Right(
          [
            for (final account in testAccounts())
              AccountWithBalance(
                account: account,
                balance: AccountBalance.fromBalance(
                  account: account,
                  balanceMinor: 0,
                ),
              ),
          ],
        ),
      ),
    );
    when(() => watchCategories(any())).thenAnswer((invocation) {
      final kind = invocation.positionalArguments.first as CategoryKind;
      final roots = [
        for (final category in testCategories())
          if (category.parentId == null && category.kind == kind)
            CategoryNode(
              root: category,
              subcategories: [
                for (final sub in testCategories())
                  if (sub.parentId == category.id) sub,
              ],
            ),
      ];
      return Stream.value(Right(roots));
    });
  });

  group('start', () {
    test('opens the microphone when every precondition holds', () async {
      final cubit = buildCubit();
      await startAndSettle(cubit);

      expect(cubit.state.status, VoiceCaptureStatus.listening);
      expect(recognizer.startCalls, 1);
      expect(recognizer.lastLocaleId, 'es_CO');
      // HU-06: the session never silently downgrades to cloud recognition.
      expect(recognizer.lastAllowCloudRecognition, isFalse);
      await cubit.close();
    });

    test('shows the explainer instead of prompting when denied', () async {
      gate.status = MicrophonePermissionStatus.denied;
      final cubit = buildCubit();
      await startAndSettle(cubit);

      expect(cubit.state.status, VoiceCaptureStatus.permissionNeeded);
      expect(cubit.state.isPermissionAskable, isTrue);
      // The system dialog is never shown without the explainer first.
      expect(gate.requestCalls, 0);
      expect(recognizer.startCalls, 0);
      await cubit.close();
    });

    test('permanently denied is not askable, so it offers settings', () async {
      gate.status = MicrophonePermissionStatus.permanentlyDenied;
      final cubit = buildCubit();
      await startAndSettle(cubit);

      expect(cubit.state.status, VoiceCaptureStatus.permissionNeeded);
      expect(cubit.state.isPermissionAskable, isFalse);
      await cubit.close();
    });

    test('an unsupported locale never falls back to another language',
        () async {
      recognizer.availability = const SpeechRecognizerAvailability(
        isAvailable: true,
        isLocaleSupported: false,
        route: SpeechRecognitionRoute.unknown,
      );
      final cubit = buildCubit();
      await startAndSettle(cubit);

      expect(cubit.state.status, VoiceCaptureStatus.unavailable);
      expect(recognizer.startCalls, 0);
      await cubit.close();
    });
  });

  group('recognition updates', () {
    test('partial results land in the state as they arrive', () async {
      final cubit = buildCubit();
      await startAndSettle(cubit);

      recognizer.controller.add(
        const SpeechRecognitionUpdate(
          phase: SpeechRecognitionPhase.listening,
          transcript: 'gasté veinte mil',
          soundLevel: 0.6,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, VoiceCaptureStatus.listening);
      expect(cubit.state.transcript, 'gasté veinte mil');
      expect(cubit.state.soundLevel, 0.6);
      expect(cubit.state.hasTranscript, isTrue);
      await cubit.close();
    });

    test('a final result with an amount completes with a parsed draft',
        () async {
      final cubit = buildCubit();
      await startAndSettle(cubit);

      recognizer.controller.add(
        const SpeechRecognitionUpdate(
          phase: SpeechRecognitionPhase.done,
          transcript: 'gasté veinte mil en mercado con Nequi',
          isFinal: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, VoiceCaptureStatus.completed);
      final draft = cubit.state.draft!;
      expect(draft.amountMinor, 2000000);
      expect(draft.type, TransactionType.expense);
      expect(draft.categoryId, 'cat-market');
      expect(draft.accountId, 'acc-nequi');
      await cubit.close();
    });

    test('a final result without an amount lands on the noAmount surface',
        () async {
      final cubit = buildCubit();
      await startAndSettle(cubit);

      recognizer.controller.add(
        const SpeechRecognitionUpdate(
          phase: SpeechRecognitionPhase.done,
          transcript: 'me tomé un tinto en la esquina',
          isFinal: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, VoiceCaptureStatus.noAmount);
      expect(cubit.state.draft!.hasAmount, isFalse);
      await cubit.close();
    });

    test('silence is an outcome, not an error the user is blamed for',
        () async {
      final cubit = buildCubit();
      await startAndSettle(cubit);

      recognizer.controller.add(
        const SpeechRecognitionUpdate(
          phase: SpeechRecognitionPhase.error,
          error: SpeechRecognitionErrorKind.noSpeech,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, VoiceCaptureStatus.noAmount);
      await cubit.close();
    });

    test('on-device unavailable is surfaced, never downgraded to cloud',
        () async {
      final cubit = buildCubit();
      await startAndSettle(cubit);

      recognizer.controller.add(
        const SpeechRecognitionUpdate(
          phase: SpeechRecognitionPhase.error,
          error: SpeechRecognitionErrorKind.onDeviceUnavailable,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, VoiceCaptureStatus.unavailable);
      expect(
        cubit.state.unavailableReason,
        VoiceCaptureUnavailableReason.onDeviceUnavailable,
      );
      await cubit.close();
    });
  });

  group('leaving', () {
    test('cancel stops the session and produces no draft', () async {
      final cubit = buildCubit();
      await startAndSettle(cubit);
      await cubit.cancel();

      expect(recognizer.cancelCalls, greaterThanOrEqualTo(1));
      expect(cubit.state.draft, isNull);
      await cubit.close();
    });

    test('close cancels the session even when nothing else did', () async {
      final cubit = buildCubit();
      await startAndSettle(cubit);
      await cubit.close();
      await Future<void>.delayed(Duration.zero);

      expect(recognizer.cancelCalls, greaterThanOrEqualTo(1));
    });

    test('stopListening keeps what was recognized', () async {
      final cubit = buildCubit();
      await startAndSettle(cubit);
      await cubit.stopListening();

      expect(recognizer.stopCalls, 1);
      await cubit.close();
    });

    test('write-by-hand still carries the transcript as a note', () async {
      final cubit = buildCubit();
      await startAndSettle(cubit);
      recognizer.controller.add(
        const SpeechRecognitionUpdate(
          phase: SpeechRecognitionPhase.done,
          transcript: 'me tomé un tinto en la esquina',
          isFinal: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.draftForManualEntry().note, isNotNull);
      await cubit.close();
    });

    test('write-by-hand with nothing said produces an empty draft', () async {
      gate.status = MicrophonePermissionStatus.permanentlyDenied;
      final cubit = buildCubit();
      await startAndSettle(cubit);

      final draft = cubit.draftForManualEntry();
      expect(draft.isEmpty, isTrue);
      expect(draft.transcript, isEmpty);
      await cubit.close();
    });
  });

  group('permission request', () {
    test('granting after the explainer starts the session', () async {
      gate
        ..status = MicrophonePermissionStatus.denied
        ..statusAfterRequest = MicrophonePermissionStatus.granted;
      final cubit = buildCubit();
      await startAndSettle(cubit);
      await cubit.requestPermission();
      await Future<void>.delayed(Duration.zero);

      expect(gate.requestCalls, 1);
      expect(cubit.state.status, VoiceCaptureStatus.listening);
      await cubit.close();
    });

    test('denying again stays on the explainer, which is never a dead end',
        () async {
      gate
        ..status = MicrophonePermissionStatus.denied
        ..statusAfterRequest = MicrophonePermissionStatus.permanentlyDenied;
      final cubit = buildCubit();
      await startAndSettle(cubit);
      await cubit.requestPermission();

      expect(cubit.state.status, VoiceCaptureStatus.permissionNeeded);
      expect(cubit.state.isPermissionAskable, isFalse);
      expect(recognizer.startCalls, 0);
      await cubit.close();
    });
  });
}
