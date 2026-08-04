import 'package:billetudo/core/theme/app_colors.dart';
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

  /// HU-08 suma el cuarto estado: `cloud-alert` en `$amber`, nunca el rojo
  /// destructivo — hay cambios esperando, nada está roto y a nadie se le está
  /// regañando.
  testWidgets(
      'atención: ícono cloud-alert y label "Cambios sin subir" '
      '(HU-08)', (tester) async {
    await tester
        .pumpHomeWidget(const SyncIndicator(status: HomeSyncStatus.attention));

    expect(find.byIcon(LucideIcons.cloudAlert), findsOneWidget);
    expect(semanticsLabelOf(tester), 'Cambios sin subir');
  });

  testWidgets('atención: el ícono va en ámbar, jamás en el rojo destructivo',
      (tester) async {
    await tester
        .pumpHomeWidget(const SyncIndicator(status: HomeSyncStatus.attention));

    final context = tester.element(find.byType(SyncIndicator));
    final colors = Theme.of(context).extension<AppColors>()!;
    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.cloudAlert));

    expect(icon.color, colors.amber);
    expect(icon.color, isNot(colors.expense));
  });

  /// El punto es la señal NO cromática, y no es opcional: a 18px `cloud-alert`
  /// y `cloud-check` tienen casi la misma silueta, así que en escala de grises
  /// el glifo solo no distingue nada.
  testWidgets('atención: el punto está presente y solo en ese estado',
      (tester) async {
    Iterable<Container> dots(WidgetTester tester) => tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(SyncIndicator),
            matching: find.byType(Container),
          ),
        )
        .where(
            (c) => (c.decoration! as BoxDecoration).shape == BoxShape.circle);

    await tester
        .pumpHomeWidget(const SyncIndicator(status: HomeSyncStatus.attention));
    expect(dots(tester), isNotEmpty);

    await tester
        .pumpHomeWidget(const SyncIndicator(status: HomeSyncStatus.synced));
    expect(dots(tester), isEmpty);
  });

  testWidgets('atención: no gira (no es progreso, es espera)', (tester) async {
    await tester
        .pumpHomeWidget(const SyncIndicator(status: HomeSyncStatus.attention));

    expect(controllerOf(tester).isAnimating, isFalse);
  });

  testWidgets('atención con onTap: área de toque de 44x44 (HU-08)',
      (tester) async {
    await tester.pumpHomeWidget(
      SyncIndicator(status: HomeSyncStatus.attention, onTap: () {}),
    );

    final size = tester.getSize(
      find.descendant(
        of: find.byType(SyncIndicator),
        matching: find.byType(InkResponse),
      ),
    );
    expect(size.width, 44);
    expect(size.height, 44);
  });

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

  testWidgets('con onTap: invoca el callback al tocar (bugfix item 6)',
      (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      SyncIndicator(
        status: HomeSyncStatus.synced,
        onTap: () => tapped++,
      ),
    );

    await tester.tap(find.byType(SyncIndicator));
    expect(tapped, 1);
  });

  testWidgets('con onTap: área de toque ≥44pt y semántica de botón',
      (tester) async {
    await tester.pumpHomeWidget(
      SyncIndicator(status: HomeSyncStatus.synced, onTap: () {}),
    );

    final size = tester.getSize(
      find.descendant(
        of: find.byType(SyncIndicator),
        matching: find.byType(InkResponse),
      ),
    );
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));

    final semantics = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byType(SyncIndicator),
        matching: find.byType(Semantics),
      ),
    );
    expect(semantics.any((s) => s.properties.button ?? false), isTrue);
  });

  testWidgets('sin onTap: pasivo, sin gesto de toque', (tester) async {
    await tester
        .pumpHomeWidget(const SyncIndicator(status: HomeSyncStatus.synced));

    expect(find.byType(InkResponse), findsNothing);
  });
}
