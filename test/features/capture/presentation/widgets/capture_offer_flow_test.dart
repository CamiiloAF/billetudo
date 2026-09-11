import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/usecases/mark_notification_capture_offered.dart';
import 'package:billetudo/features/capture/domain/usecases/should_offer_notification_capture.dart';
import 'package:billetudo/features/capture/presentation/widgets/sheets/capture_offer_flow.dart';
import 'package:billetudo/features/capture/presentation/widgets/sheets/capture_offer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../auth/presentation/widgets/pump_widget.dart';
import '../../capture_mocks.dart';

/// The contextual offer of HU-01, driven end to end.
///
/// Worth a widget test of its own because every failure mode here is
/// **silent**: the offer simply does not appear, and the feature stays
/// unreachable for anyone who never opens Ajustes. Nothing throws, nothing
/// logs, and no other test would notice.
void main() {
  late MockNotificationCaptureRepository capture;
  late MockCaptureOfferRepository offer;

  setUp(() {
    capture = MockNotificationCaptureRepository();
    offer = MockCaptureOfferRepository();
    when(offer.markOffered).thenAnswer((_) async => const Right(unit));
  });

  void stubEligible({required bool eligible}) {
    when(() => capture.isSupported).thenReturn(true);
    when(offer.hasBeenOffered).thenAnswer((_) async => Right(!eligible));
    when(capture.isPermissionGranted)
        .thenAnswer((_) async => const Right(false));
  }

  Future<int> pumpOffer(WidgetTester tester) async {
    int seeHowCalls = 0;
    await tester.pumpAuthWidget(
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => CaptureOfferFlow.maybeOffer(
            context,
            shouldOffer: ShouldOfferNotificationCapture(capture, offer),
            markOffered: MarkNotificationCaptureOffered(offer),
            onSeeHowItWorks: () => seeHowCalls++,
          ),
          child: const Text('save'),
        ),
      ),
    );
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
    return seeHowCalls;
  }

  testWidgets('offers the permission after a manual expense', (tester) async {
    stubEligible(eligible: true);

    await pumpOffer(tester);

    expect(find.byType(CaptureOfferSheet), findsOneWidget);
  });

  testWidgets(
      'the copy states the condition and never promises that '
      'everything is captured on its own', (tester) async {
    stubEligible(eligible: true);

    await pumpOffer(tester);

    // The condition ("cuando tu banco te avise..."), not "¿quieres que esto
    // aparezca solo?" — the app cannot capture cash or banks outside the
    // catalog, and a promise of full automation breaks on the first expense
    // that never shows up.
    expect(
      find.textContaining('Cuando tu banco te avise de una compra'),
      findsOneWidget,
    );
    expect(
      find.textContaining('el efectivo no avisa'),
      findsOneWidget,
    );
  });

  testWidgets('always offers a way out with the same weight as the CTA',
      (tester) async {
    stubEligible(eligible: true);

    await pumpOffer(tester);

    expect(find.text('Ahora no'), findsOneWidget);
    expect(find.text('Ver cómo funciona'), findsOneWidget);
  });

  testWidgets(
      'latches the offer even when the user declines, so it is never '
      'asked twice', (tester) async {
    stubEligible(eligible: true);

    await pumpOffer(tester);
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    verify(offer.markOffered).called(1);
    expect(find.byType(CaptureOfferSheet), findsNothing);
  });

  testWidgets('"Ver cómo funciona" hands off to the explainer', (tester) async {
    stubEligible(eligible: true);
    int seeHowCalls = 0;

    await tester.pumpAuthWidget(
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => CaptureOfferFlow.maybeOffer(
            context,
            shouldOffer: ShouldOfferNotificationCapture(capture, offer),
            markOffered: MarkNotificationCaptureOffered(offer),
            onSeeHowItWorks: () => seeHowCalls++,
          ),
          child: const Text('save'),
        ),
      ),
    );
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver cómo funciona'));
    await tester.pumpAndSettle();

    expect(seeHowCalls, 1);
  });

  testWidgets('shows nothing when the device is not eligible', (tester) async {
    stubEligible(eligible: false);

    await pumpOffer(tester);

    expect(find.byType(CaptureOfferSheet), findsNothing);
    verifyNever(offer.markOffered);
  });
}
