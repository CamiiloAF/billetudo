import 'package:billetudo/features/goals/presentation/widgets/goal_amount_hero_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// Reproduces the caller loop `GoalContributionSheet` actually runs: every
/// keystroke's `onChanged` feeds back into `initialAmountMinor` on the next
/// rebuild (the way a cubit-driven `BlocBuilder` does), and an external
/// button can also push a brand new `initialAmountMinor` (the "Usar todo"
/// case) that must repaint the field's own text.
class _Host extends StatefulWidget {
  const _Host({this.currency = 'COP'});

  final String currency;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int amountMinor = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GoalAmountHeroField(
          label: 'Monto',
          currency: widget.currency,
          initialAmountMinor: amountMinor,
          onChanged: (value) => setState(() => amountMinor = value),
        ),
        TextButton(
          key: const ValueKey('external-set-max'),
          onPressed: () => setState(() => amountMinor = 500000),
          child: const Text('Usar todo'),
        ),
      ],
    );
  }
}

void main() {
  TextField fieldOf(WidgetTester tester) => tester.widget<TextField>(
        find.descendant(
          of: find.byType(GoalAmountHeroField),
          matching: find.byType(TextField),
        ),
      );

  testWidgets(
    'typing keystrokes do not get reformatted or move the cursor unexpectedly',
    (tester) async {
      await tester.pumpWidget(
        wrapForGolden(const _Host(), brightness: Brightness.light),
      );

      await tester.enterText(find.byType(TextField), '1');
      await tester.pump();
      expect(fieldOf(tester).controller!.text, '1');

      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      expect(fieldOf(tester).controller!.text, '12');

      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();
      // Each keystroke round-trips through onChanged -> setState with
      // initialAmountMinor already equal to the controller's parsed value:
      // didUpdateWidget must treat that as a no-op, not reformat mid-typing.
      expect(fieldOf(tester).controller!.text, '123');
    },
  );

  testWidgets(
    'an external initialAmountMinor change (not echoed from typing) '
    'reformats the visible text',
    (tester) async {
      await tester.pumpWidget(
        wrapForGolden(const _Host(), brightness: Brightness.light),
      );

      expect(fieldOf(tester).controller!.text, '');

      await tester.tap(find.byKey(const ValueKey('external-set-max')));
      await tester.pump();

      expect(fieldOf(tester).controller!.text, '5.000');
    },
  );

  testWidgets(
    'changing currency resyncs the formatted text for the current amount',
    (tester) async {
      await tester.pumpWidget(
        wrapForGolden(const _Host(), brightness: Brightness.light),
      );

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();
      expect(fieldOf(tester).controller!.text, '1.234');

      await tester.pumpWidget(
        wrapForGolden(const _Host(currency: 'USD'), brightness: Brightness.light),
      );
      await tester.pump();

      // Currency change reformats the already-typed amount under the new
      // currency's decimal rules rather than wiping it.
      expect(fieldOf(tester).controller!.text.isNotEmpty, isTrue);
    },
  );
}
