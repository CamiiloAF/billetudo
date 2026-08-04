import 'package:billetudo/features/goals/domain/services/goal_milestone_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tracker = GoalMilestoneTracker();

  group('evaluate — HU-06', () {
    test('cruzar 25% por primera vez celebra 25', () {
      final outcome = tracker.evaluate(
        previousLastMilestonePct: 0,
        newRawPercent: 30,
      );

      expect(outcome.crossedMilestonePct, 25);
      expect(outcome.lastMilestonePct, 25);
    });

    test('un solo aporte que salta de 0% a 80% celebra solo el más alto (75)', () {
      final outcome = tracker.evaluate(
        previousLastMilestonePct: 0,
        newRawPercent: 80,
      );

      expect(outcome.crossedMilestonePct, 75);
      expect(outcome.lastMilestonePct, 75);
    });

    test('cruzar 100% celebra 100 aunque venga de 75 ya celebrado', () {
      final outcome = tracker.evaluate(
        previousLastMilestonePct: 75,
        newRawPercent: 100,
      );

      expect(outcome.crossedMilestonePct, 100);
    });

    test(
      'idempotente: oscilar de vuelta al mismo umbral ya celebrado no vuelve '
      'a celebrar',
      () {
        // 50% ya celebrado; un retiro lo baja a 48%, un aporte lo vuelve a 51%.
        final afterDip = tracker.evaluate(
          previousLastMilestonePct: 50,
          newRawPercent: 48,
        );
        expect(afterDip.crossedMilestonePct, isNull);
        expect(afterDip.lastMilestonePct, 50);

        final afterRecover = tracker.evaluate(
          previousLastMilestonePct: afterDip.lastMilestonePct,
          newRawPercent: 51,
        );
        expect(afterRecover.crossedMilestonePct, isNull);
        expect(afterRecover.lastMilestonePct, 50);
      },
    );

    test('bajar de 40% a 10% no celebra nada nuevo', () {
      final outcome = tracker.evaluate(
        previousLastMilestonePct: 25,
        newRawPercent: 10,
      );

      expect(outcome.crossedMilestonePct, isNull);
      expect(outcome.lastMilestonePct, 25);
    });
  });

  group('reconcileAfterTargetChange — HU-06/HU-07', () {
    test(
      'subir targetMinor y caer del 100% al 40% reajusta lastMilestonePct al '
      'umbral vigente (25), no a 0',
      () {
        final reconciled = tracker.reconcileAfterTargetChange(
          currentLastMilestonePct: 100,
          newRawPercent: 40,
        );

        expect(reconciled, 25);
      },
    );

    test('bajar targetMinor y subir el porcentaje nunca celebra aquí', () {
      final reconciled = tracker.reconcileAfterTargetChange(
        currentLastMilestonePct: 25,
        newRawPercent: 120,
      );

      // Never moves UP on a target change — only `evaluate` (driven by an
      // actual movement) celebrates.
      expect(reconciled, 25);
    });
  });
}
