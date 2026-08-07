import 'package:billetudo/features/home/presentation/widgets/month_selector_chip.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

/// Non-golden coverage for [MonthSelectorChip] (HU-04, `A9v7s` `HC Month`):
/// the pixel-level look (fill/typography/light-dark parity) is asserted via
/// `home_page_golden_test.dart`; this file covers the widget's own contract —
/// it renders the given [MonthSelectorChip.label] and taps invoke
/// [MonthSelectorChip.onTap].
void main() {
  testWidgets('renderiza el label del mes recibido', (tester) async {
    await tester.pumpHomeWidget(
      MonthSelectorChip(label: 'Julio', onTap: () {}),
    );

    expect(find.text('Julio'), findsOneWidget);
  });

  testWidgets('tocarlo dispara onTap', (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      MonthSelectorChip(label: 'Julio', onTap: () => tapped++),
    );

    await tester.tap(find.byType(MonthSelectorChip));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('expone semántica de botón con el tooltip localizado',
      (tester) async {
    await tester.pumpHomeWidget(
      MonthSelectorChip(label: 'Julio', onTap: () {}),
    );

    final semantics = tester.getSemantics(find.byType(MonthSelectorChip));
    expect(semantics.flagsCollection.isButton, isTrue);
    // Merged with the tooltip's own semantics child ("Julio"): the chip's
    // own explicit label is the first line.
    expect(semantics.label, startsWith('Cambiar mes'));
  });
}
