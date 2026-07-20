import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pump_widget.dart';

void main() {
  // `getSemantics` needs the semantics tree built; the indicator is passive,
  // so its label is the only thing a screen reader can announce.
  /// Reads the label a screen reader would announce. The handle is disposed
  /// before returning: `addTearDown` runs too late for the framework's
  /// end-of-test check on live semantics handles.
  String semanticsLabelOf(WidgetTester tester) {
    final handle = tester.ensureSemantics();
    final label = tester.getSemantics(find.byType(SyncIndicator)).label;
    handle.dispose();
    return label;
  }

  AnimationController controllerOf(WidgetTester tester) {
    final transition = tester.widget<RotationTransition>(
      find.descendant(
        of: find.byType(SyncIndicator),
        matching: find.byType(RotationTransition),
      ),
    );
    return transition.turns as AnimationController;
  }

  Widget reducedMotion(Widget child) => Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child,
        ),
      );

  /// The indicator is passive (never a tap target), so the semantics label is
  /// the only way a screen reader learns the sync state — it must be there in
  /// every state, animated or not.
  for (final (status, icon, label) in const [
    (HomeSyncStatus.synced, LucideIcons.cloudCheck, 'Sincronizado'),
    (HomeSyncStatus.syncing, LucideIcons.refreshCw, 'Sincronizando…'),
    (HomeSyncStatus.offline, LucideIcons.cloudOff, 'Sin conexión'),
  ]) {
    testWidgets('$status: ícono $icon y label "$label" (HU-10)',
        (tester) async {
      await tester.pumpHomeWidget(SyncIndicator(status: status));

      expect(find.byIcon(icon), findsOneWidget);
      expect(semanticsLabelOf(tester), label);

      // Drop the widget so a spinning controller does not outlive the test.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('sincronizando: el ícono de refresco gira (HU-10)',
      (tester) async {
    await tester
        .pumpHomeWidget(const SyncIndicator(status: HomeSyncStatus.syncing));

    expect(find.byIcon(LucideIcons.refreshCw), findsOneWidget);
    expect(controllerOf(tester).isAnimating, isTrue);

    // Let the pending animation settle so the test can end cleanly.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('sincronizado y sin conexión: ícono estático (HU-10)',
      (tester) async {
    await tester
        .pumpHomeWidget(const SyncIndicator(status: HomeSyncStatus.synced));
    expect(find.byIcon(LucideIcons.cloudCheck), findsOneWidget);
    expect(controllerOf(tester).isAnimating, isFalse);

    await tester
        .pumpHomeWidget(const SyncIndicator(status: HomeSyncStatus.offline));
    expect(find.byIcon(LucideIcons.cloudOff), findsOneWidget);
    expect(controllerOf(tester).isAnimating, isFalse);
  });

  testWidgets('al salir de sincronizando el controlador se detiene',
      (tester) async {
    await tester
        .pumpHomeWidget(const SyncIndicator(status: HomeSyncStatus.syncing));
    expect(controllerOf(tester).isAnimating, isTrue);

    await tester
        .pumpHomeWidget(const SyncIndicator(status: HomeSyncStatus.synced));
    final controller = controllerOf(tester);
    expect(controller.isAnimating, isFalse);
    expect(controller.value, 0);
  });

  testWidgets('movimiento reducido: no anima (accesibilidad)', (tester) async {
    await tester.pumpHomeWidget(
      reducedMotion(const SyncIndicator(status: HomeSyncStatus.syncing)),
    );

    expect(find.byIcon(LucideIcons.refreshCw), findsOneWidget);
    expect(controllerOf(tester).isAnimating, isFalse);
    // The icon freezes, but the screen reader still gets the progress label.
    expect(semanticsLabelOf(tester), 'Sincronizando…');
  });
}
