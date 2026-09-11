import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/widgets/permission_fact_row.dart';
import 'package:billetudo/features/capture/presentation/cubit/voice_capture_state.dart';
import 'package:billetudo/features/capture/presentation/widgets/voice_capture_listening_body.dart';
import 'package:billetudo/features/capture/presentation/widgets/voice_capture_no_amount_body.dart';
import 'package:billetudo/features/capture/presentation/widgets/voice_capture_permission_body.dart';
import 'package:billetudo/features/capture/presentation/widgets/voice_capture_unavailable_body.dart';
import 'package:billetudo/features/capture/presentation/widgets/voice_listening_indicator.dart';
import 'package:billetudo/features/capture/presentation/widgets/voice_transcript_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/golden_helpers.dart';

/// The four designed surfaces of the capture sheet (`f8OP8a`, `Z6imP`,
/// `lLKTv`, `tN3NS`), asserted against the real `AppLocalizations` copy rather
/// than hand-typed strings, so a wording regression in the `.arb` fails here.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  late AppLocalizations l10n;

  Future<void> pumpBody(WidgetTester tester, Widget body) async {
    setGoldenViewport(tester, goldenPhoneSize);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return SingleChildScrollView(child: body);
          },
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('listening (f8OP8a / Z6imP)', () {
    testWidgets('with nothing said yet it shows the hint and the privacy line',
        (tester) async {
      await pumpBody(
        tester,
        VoiceCaptureListeningBody(
          state: const VoiceCaptureState(status: VoiceCaptureStatus.listening),
          onCancel: () {},
          onDone: () {},
        ),
      );

      expect(find.text(l10n.captureVoiceListening), findsOneWidget);
      expect(find.text(l10n.captureVoiceHint), findsOneWidget);
      expect(find.text(l10n.captureVoicePrivacyCaption), findsOneWidget);
      // Cancelar is always available and never competes with Listo.
      expect(find.text(l10n.captureVoiceCancel), findsOneWidget);
      expect(find.text(l10n.captureVoiceDone), findsOneWidget);
    });

    testWidgets('a partial result is shown live and swaps the caption',
        (tester) async {
      await pumpBody(
        tester,
        VoiceCaptureListeningBody(
          state: const VoiceCaptureState(
            status: VoiceCaptureStatus.listening,
            transcript: 'gasté veinte mil en almuerzo con Nequi',
            soundLevel: 0.7,
          ),
          onCancel: () {},
          onDone: () {},
        ),
      );

      expect(
        find.text('gasté veinte mil en almuerzo con Nequi'),
        findsOneWidget,
      );
      expect(find.text(l10n.captureVoicePartialCaption), findsOneWidget);
      expect(find.text(l10n.captureVoicePrivacyCaption), findsNothing);
    });

    testWidgets('a long dictation is never truncated (HU-09)', (tester) async {
      const long =
          'gasté cuarenta y siete mil quinientos pesos en el almuerzo de '
          'trabajo del martes con los compañeros del equipo de diseño en el '
          'restaurante nuevo que abrieron cerca de la oficina y lo pagué con '
          'la cuenta de Bancolombia';
      await pumpBody(
        tester,
        const VoiceCaptureListeningBody(
          state: VoiceCaptureState(
            status: VoiceCaptureStatus.listening,
            transcript: long,
          ),
          onCancel: _noop,
          onDone: _noop,
        ),
      );

      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(VoiceTranscriptBox),
          matching: find.byType(Text),
        ),
      );
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the state is not carried by motion alone', (tester) async {
      await pumpBody(
        tester,
        VoiceCaptureListeningBody(
          state: const VoiceCaptureState(status: VoiceCaptureStatus.listening),
          onCancel: () {},
          onDone: () {},
        ),
      );

      // The label is the signal that can never be switched off.
      expect(find.byType(VoiceListeningIndicator), findsOneWidget);
      expect(find.text(l10n.captureVoiceListening), findsOneWidget);
    });
  });

  group('no amount (lLKTv)', () {
    testWidgets('keeps the transcript and offers both exits', (tester) async {
      await pumpBody(
        tester,
        VoiceCaptureNoAmountBody(
          transcript: 'me tomé un tinto en la esquina',
          onRetry: () {},
          onWriteByHand: () {},
        ),
      );

      expect(find.text(l10n.captureVoiceNoAmountTitle), findsOneWidget);
      expect(find.text(l10n.captureVoiceNoAmountMessage), findsOneWidget);
      expect(find.text('me tomé un tinto en la esquina'), findsOneWidget);
      expect(find.text(l10n.captureVoiceRetry), findsOneWidget);
      expect(find.text(l10n.captureVoiceWriteByHand), findsOneWidget);
    });

    testWidgets('both exits are wired', (tester) async {
      var retried = 0;
      var byHand = 0;
      await pumpBody(
        tester,
        VoiceCaptureNoAmountBody(
          transcript: 'un tinto',
          onRetry: () => retried++,
          onWriteByHand: () => byHand++,
        ),
      );

      await tester.tap(find.text(l10n.captureVoiceRetry));
      await tester.tap(find.text(l10n.captureVoiceWriteByHand));
      expect(retried, 1);
      expect(byHand, 1);
    });
  });

  group('permission (tN3NS)', () {
    testWidgets('while askable it asks, and is never a dead end',
        (tester) async {
      var requested = 0;
      await pumpBody(
        tester,
        VoiceCapturePermissionBody(
          canRequest: true,
          onRequest: () => requested++,
          onOpenSettings: () {},
          onWriteByHand: () {},
        ),
      );

      expect(find.text(l10n.captureVoicePermissionTitle), findsOneWidget);
      expect(find.byType(PermissionFactRow), findsNWidgets(3));
      expect(find.text(l10n.captureVoicePermissionAllow), findsOneWidget);
      // Nivel 0 escape hatch, always present.
      expect(find.text(l10n.captureVoiceWriteByHand), findsOneWidget);

      await tester.tap(find.text(l10n.captureVoicePermissionAllow));
      expect(requested, 1);
    });

    testWidgets('once permanent it stops nagging and links to settings',
        (tester) async {
      var settings = 0;
      await pumpBody(
        tester,
        VoiceCapturePermissionBody(
          canRequest: false,
          onRequest: () {},
          onOpenSettings: () => settings++,
          onWriteByHand: () {},
        ),
      );

      expect(
          find.text(l10n.captureVoicePermissionOpenSettings), findsOneWidget);
      expect(find.text(l10n.captureVoicePermissionAllow), findsNothing);

      await tester.tap(find.text(l10n.captureVoicePermissionOpenSettings));
      expect(settings, 1);
    });
  });

  group('unavailable', () {
    testWidgets('on-device unavailable says so instead of blaming the phone',
        (tester) async {
      await pumpBody(
        tester,
        VoiceCaptureUnavailableBody(
          reason: VoiceCaptureUnavailableReason.onDeviceUnavailable,
          onRetry: () {},
          onWriteByHand: () {},
        ),
      );

      expect(
        find.text(l10n.captureVoiceOnDeviceUnavailableMessage),
        findsOneWidget,
      );
      // Retrying would fail identically, so it is not offered.
      expect(find.text(l10n.captureVoiceRetry), findsNothing);
      expect(find.text(l10n.captureVoiceWriteByHand), findsOneWidget);
    });

    testWidgets('a busy microphone can be retried', (tester) async {
      await pumpBody(
        tester,
        VoiceCaptureUnavailableBody(
          reason: VoiceCaptureUnavailableReason.busy,
          onRetry: () {},
          onWriteByHand: () {},
        ),
      );

      expect(find.text(l10n.captureVoiceBusyMessage), findsOneWidget);
      expect(find.text(l10n.captureVoiceRetry), findsOneWidget);
    });
  });
}

void _noop() {}
