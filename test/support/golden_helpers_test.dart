import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  testWidgets(
    'pumpWithFixedClock pins clock.now() to goldenReferenceNow while the '
    'widget tree builds',
    (WidgetTester tester) async {
      DateTime? observedNow;

      await pumpWithFixedClock(
        tester,
        Builder(
          builder: (BuildContext context) {
            observedNow = clock.now();
            return const SizedBox.shrink();
          },
        ),
        brightness: Brightness.light,
      );

      expect(
        observedNow,
        goldenReferenceNow,
        reason:
            'widgets built inside pumpWithFixedClock must read the fixed '
            'reference date, not the real wall clock',
      );
    },
  );

  testWidgets(
    'pumpWithFixedClock accepts an explicit fixedNow override instead of '
    'the shared goldenReferenceNow',
    (WidgetTester tester) async {
      final DateTime override = DateTime(2020, 1, 1);
      DateTime? observedNow;

      await pumpWithFixedClock(
        tester,
        Builder(
          builder: (BuildContext context) {
            observedNow = clock.now();
            return const SizedBox.shrink();
          },
        ),
        brightness: Brightness.light,
        fixedNow: override,
      );

      expect(observedNow, override);
    },
  );

  testWidgets(
    'the fixed clock does not leak outside pumpWithFixedClock',
    (WidgetTester tester) async {
      await pumpWithFixedClock(
        tester,
        const SizedBox.shrink(),
        brightness: Brightness.light,
      );

      final DateTime realNow = clock.now();
      final Duration drift = DateTime.now().difference(realNow).abs();

      expect(
        drift < const Duration(minutes: 1),
        isTrue,
        reason:
            'clock.now() must resolve back to the real wall clock once '
            'pumpWithFixedClock returns, otherwise later tests in the same '
            'run would silently inherit the fixed golden date',
      );
    },
  );
}
