import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/settings/presentation/widgets/cloud_transcription_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// "Transcribir mi voz en la nube" in Ajustes.
///
/// This row is the reversal the consent sheet (`kJG43`) promises in writing.
/// The tests are about that promise being real: the switch reflects the
/// stored decision, moves in both directions, and names the third party the
/// same way the sheet does.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  late AppLocalizations l10n;

  Future<void> pumpField(
    WidgetTester tester, {
    required bool enabled,
    TargetPlatform platform = TargetPlatform.android,
    ValueChanged<bool>? onChanged,
  }) async {
    setGoldenViewport(tester, goldenPhoneSize);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return Theme(
              data: Theme.of(context).copyWith(platform: platform),
              child: CloudTranscriptionField(
                enabled: enabled,
                onChanged: onChanged ?? (_) {},
              ),
            );
          },
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('names what it does and where the audio goes', (tester) async {
    await pumpField(tester, enabled: false);

    expect(find.text(l10n.settingsCloudTranscription), findsOneWidget);
    // The subtitle is what makes the switch informed; a row saying only "en la
    // nube" would be the silent version of this decision.
    expect(
      find.text(
        l10n.settingsCloudTranscriptionSubtitle(l10n.captureVoiceVendorGoogle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('on iOS it names Apple, matching the sheet', (tester) async {
    await pumpField(tester, enabled: false, platform: TargetPlatform.iOS);

    expect(
      find.text(
        l10n.settingsCloudTranscriptionSubtitle(l10n.captureVoiceVendorApple),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the switch reflects the stored decision', (tester) async {
    await pumpField(tester, enabled: true);

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('withdrawing takes one tap and no confirmation', (tester) async {
    final requested = <bool>[];
    await pumpField(
      tester,
      enabled: true,
      onChanged: requested.add,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(requested, [false]);
  });

  testWidgets('granting it again from here is equally one tap', (tester) async {
    final requested = <bool>[];
    await pumpField(
      tester,
      enabled: false,
      onChanged: requested.add,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(requested, [true]);
  });
}
