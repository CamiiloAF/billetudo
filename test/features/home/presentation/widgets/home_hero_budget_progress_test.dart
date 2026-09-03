import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_budget_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

/// Criterio 8: la barra nunca deja un hueco de <10px con esquina redondeada
/// suelta — por debajo de ese umbral de remanente, el tramo/track usa
/// esquina recta en vez de radio 5 en ambos extremos.
void main() {
  const trackWidth = 300.0;

  Future<BorderRadius?> pumpAndGetSpentRadius(
    WidgetTester tester,
    BudgetProgress progress,
  ) async {
    await tester.pumpHomeWidget(
      SizedBox(
        width: trackWidth,
        child: HomeHeroBudgetProgress(
          progress: progress,
          spentColor: Colors.white,
        ),
      ),
    );
    final containers = tester.widgetList<Container>(find.byType(Container));
    // The spent segment is the first `Container` whose decoration paints the
    // `spentColor` fill.
    for (final container in containers) {
      final decoration = container.decoration;
      if (decoration is BoxDecoration && decoration.color == Colors.white) {
        return decoration.borderRadius as BorderRadius?;
      }
    }
    return null;
  }

  testWidgets(
      'remanente amplio (>=10px): la esquina derecha del tramo conserva '
      'radio 5', (tester) async {
    // 90% spent of 300px track => remainder = 30px, well above the 10px
    // threshold.
    const progress =
        BudgetProgress(amountMinor: 100000, spentMinor: 90000, daysLeft: 5);
    final radius = await pumpAndGetSpentRadius(tester, progress);

    expect(radius?.topRight, const Radius.circular(5));
    expect(radius?.bottomRight, const Radius.circular(5));
  });

  testWidgets(
      'remanente angosto (<10px): la esquina derecha del tramo pasa a recta',
      (tester) async {
    // 97% spent of 300px track => spentWidth = 291px, remainder = 9px < 10px.
    const progress =
        BudgetProgress(amountMinor: 100000, spentMinor: 97000, daysLeft: 1);
    final radius = await pumpAndGetSpentRadius(tester, progress);

    expect(radius?.topRight, Radius.zero);
    expect(radius?.bottomRight, Radius.zero);
  });

  testWidgets('remanente cero (100%): esquina derecha recta', (tester) async {
    const progress =
        BudgetProgress(amountMinor: 100000, spentMinor: 100000, daysLeft: 0);
    final radius = await pumpAndGetSpentRadius(tester, progress);

    expect(radius?.topRight, Radius.zero);
    expect(radius?.bottomRight, Radius.zero);
  });

  testWidgets(
      'con un segundo tramo (scheduledMinor > 0), el tramo gastado siempre '
      'queda recto a la derecha — el radio 5 lo cierra el tramo programado',
      (tester) async {
    const progress = BudgetProgress(
      amountMinor: 100000,
      spentMinor: 30000,
      scheduledMinor: 20000,
      daysLeft: 5,
    );
    final radius = await pumpAndGetSpentRadius(tester, progress);

    expect(radius?.topRight, Radius.zero);
    expect(radius?.bottomRight, Radius.zero);
  });

  testWidgets(
      'la esquina izquierda del tramo gastado siempre mantiene '
      'radio 5 (nunca colapsa, solo la derecha lo hace)', (tester) async {
    const progress =
        BudgetProgress(amountMinor: 100000, spentMinor: 97000, daysLeft: 1);
    final radius = await pumpAndGetSpentRadius(tester, progress);

    expect(radius?.topLeft, const Radius.circular(5));
    expect(radius?.bottomLeft, const Radius.circular(5));
  });

  group('color del tramo "programado" (issue #11)', () {
    Future<Color?> pumpAndGetScheduledColor(
      WidgetTester tester,
      BudgetProgress progress,
    ) async {
      await tester.pumpHomeWidget(
        SizedBox(
          width: trackWidth,
          child: HomeHeroBudgetProgress(
            progress: progress,
            spentColor: Colors.white,
          ),
        ),
      );
      final context = tester.element(find.byType(HomeHeroBudgetProgress));
      final colors = context.colors;
      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final container in containers) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration &&
            (decoration.color == colors.onPrimaryScheduled ||
                decoration.color == colors.onPrimaryWarn)) {
          return decoration.color;
        }
      }
      return null;
    }

    testWidgets(
        'scheduledMinor > 0 SIN riesgo real: el segundo tramo se dibuja '
        'igual (no se oculta, patron de Presupuestos) pero en '
        'onPrimaryScheduled, no en onPrimaryWarn', (tester) async {
      // spent (30%) + scheduled (20%) = 50% comprometido, lejos del
      // presupuesto: sin riesgo.
      const progress = BudgetProgress(
        amountMinor: 100000,
        spentMinor: 30000,
        scheduledMinor: 20000,
        daysLeft: 5,
      );
      expect(progress.isScheduledOverspendRisk, isFalse);

      final color = await pumpAndGetScheduledColor(tester, progress);

      final colors = tester.element(find.byType(HomeHeroBudgetProgress)).colors;
      expect(
        color,
        colors.onPrimaryScheduled,
        reason: 'el tramo programado debe existir y usar el color '
            '"sin riesgo", nunca el de riesgo',
      );
    });

    testWidgets(
        'con riesgo real de sobregiro proyectado: el segundo tramo usa '
        'onPrimaryWarn', (tester) async {
      // spent (30%) + scheduled (80%) = 110% comprometido, riesgo real.
      const progress = BudgetProgress(
        amountMinor: 100000,
        spentMinor: 30000,
        scheduledMinor: 80000,
        daysLeft: 5,
      );
      expect(progress.isScheduledOverspendRisk, isTrue);

      final color = await pumpAndGetScheduledColor(tester, progress);

      final colors = tester.element(find.byType(HomeHeroBudgetProgress)).colors;
      expect(color, colors.onPrimaryWarn);
    });
  });
}
