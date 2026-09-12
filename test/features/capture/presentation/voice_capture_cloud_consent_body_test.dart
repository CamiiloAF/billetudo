import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/widgets/permission_fact_row.dart';
import 'package:billetudo/features/capture/presentation/widgets/voice_capture_cloud_consent_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/golden_helpers.dart';

/// The cloud-transcription consent sheet (`kJG43`).
///
/// Asserted against the real `AppLocalizations` copy rather than hand-typed
/// strings: the whole point of this surface is *what it says*, so a wording
/// regression in the `.arb` has to fail here.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  late AppLocalizations l10n;

  /// The platform is injected through the theme rather than
  /// `debugDefaultTargetPlatformOverride`: the widget reads
  /// `Theme.of(context).platform`, and a debug foundation variable left set
  /// at the end of a test body trips the framework's own invariant check.
  Future<void> pumpBody(
    WidgetTester tester, {
    TargetPlatform platform = TargetPlatform.android,
    VoidCallback? onAllow,
    VoidCallback? onWriteByHand,
  }) async {
    setGoldenViewport(tester, goldenPhoneSize);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return Theme(
              data: Theme.of(context).copyWith(platform: platform),
              child: SingleChildScrollView(
                child: VoiceCaptureCloudConsentBody(
                  onAllow: onAllow ?? () {},
                  onWriteByHand: onWriteByHand ?? () {},
                ),
              ),
            );
          },
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('states the three facts and both exits', (tester) async {
    await pumpBody(tester);

    expect(find.byType(PermissionFactRow), findsNWidgets(3));
    expect(find.text(l10n.captureVoiceCloudConsentFact1Title), findsOneWidget);
    expect(find.text(l10n.captureVoiceCloudConsentFact2Title), findsOneWidget);
    expect(find.text(l10n.captureVoiceCloudConsentFact3Title), findsOneWidget);
    // Two exits of equal weight: "Escribir a mano" is Nivel 0 and is never a
    // secondary link tucked under the other one.
    expect(find.text(l10n.captureVoiceCloudConsentAllow), findsOneWidget);
    expect(find.text(l10n.captureVoiceWriteByHand), findsOneWidget);
    // `byWidgetPredicate`, not `byType`: `.icon` builds a private subclass and
    // `find.byType` matches the exact runtime type only.
    expect(
      find.byWidgetPredicate((widget) => widget is FilledButton),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is OutlinedButton),
      findsOneWidget,
    );
  });

  testWidgets('promises the reversal Ajustes actually implements',
      (tester) async {
    await pumpBody(tester);

    expect(
      find.text(l10n.captureVoiceCloudConsentReversible),
      findsOneWidget,
    );
  });

  testWidgets('on Android it names Google, never Apple', (tester) async {
    await pumpBody(tester);

    final google = l10n.captureVoiceVendorGoogle;
    expect(
      find.text(l10n.captureVoiceCloudConsentTitle(google)),
      findsOneWidget,
    );
    expect(
      find.text(l10n.captureVoiceCloudConsentMessage(google)),
      findsOneWidget,
    );
    expect(
      find.textContaining(l10n.captureVoiceVendorApple),
      findsNothing,
    );
  });

  testWidgets('on iOS the same sheet names Apple, never Google',
      (tester) async {
    await pumpBody(tester, platform: TargetPlatform.iOS);

    final apple = l10n.captureVoiceVendorApple;
    expect(
      find.text(l10n.captureVoiceCloudConsentTitle(apple)),
      findsOneWidget,
    );
    expect(
      find.text(l10n.captureVoiceCloudConsentFact1Body(apple)),
      findsOneWidget,
    );
    expect(
      find.textContaining(l10n.captureVoiceVendorGoogle),
      findsNothing,
    );
  });

  testWidgets('each CTA reports its own choice', (tester) async {
    var allowed = 0;
    var byHand = 0;
    await pumpBody(
      tester,
      onAllow: () => allowed++,
      onWriteByHand: () => byHand++,
    );

    await tester.tap(find.text(l10n.captureVoiceCloudConsentAllow));
    await tester.pump();
    expect(allowed, 1);
    expect(byHand, isZero);

    await tester.tap(find.text(l10n.captureVoiceWriteByHand));
    await tester.pump();
    expect(byHand, 1);
    expect(allowed, 1);
  });
}
