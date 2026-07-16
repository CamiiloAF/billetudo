import 'package:billetudo/features/home/presentation/pages/more_page.dart';
import 'package:billetudo/features/home/presentation/widgets/coming_soon_badge.dart';
import 'package:billetudo/features/home/presentation/widgets/more_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/pump_widget.dart';

void main() {
  Future<void> pumpMore(
    WidgetTester tester, {
    VoidCallback? onAccounts,
    VoidCallback? onCategories,
    ValueChanged<String>? onComingSoon,
    VoidCallback? onSettings,
    VoidCallback? onSignOut,
    bool isSignedIn = false,
  }) =>
      tester.pumpHomeWidget(
        MorePage(
          onOpenAccounts: onAccounts ?? () {},
          onOpenCategories: onCategories ?? () {},
          onOpenComingSoon: onComingSoon ?? (_) {},
          onOpenSettings: onSettings ?? () {},
          isSignedIn: isSignedIn,
          onSignOut: onSignOut ?? () {},
        ),
        wrapInScaffold: false,
      );

  testWidgets('lista todos los destinos de Nivel 0 (HU-01)', (tester) async {
    await pumpMore(tester);

    for (final label in [
      'Cuentas',
      'Categorías',
      'Deudas',
      'Recurrentes',
      'Gráficas e informes',
      'Importar y exportar',
      'Ajustes',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets(
      'Cuentas, Categorías y Ajustes están vivas (sin badge Próximamente)',
      (tester) async {
    await pumpMore(tester);

    // Three live rows, four not-yet-built ones carrying the badge.
    expect(find.byType(ComingSoonBadge), findsNWidgets(4));

    ComingSoonBadge? badgeOf(String label) {
      final row = find.ancestor(
        of: find.text(label),
        matching: find.byType(MoreRow),
      );
      final badges = find.descendant(
        of: row,
        matching: find.byType(ComingSoonBadge),
      );
      return badges.evaluate().isEmpty
          ? null
          : tester.widget<ComingSoonBadge>(badges);
    }

    expect(badgeOf('Cuentas'), isNull);
    expect(badgeOf('Categorías'), isNull);
    expect(badgeOf('Ajustes'), isNull);
    expect(badgeOf('Deudas'), isNotNull);
  });

  testWidgets('tocar Ajustes enruta a Ajustes', (tester) async {
    var settings = 0;
    await pumpMore(tester, onSettings: () => settings++);

    await tester.tap(find.text('Ajustes'));
    await tester.pump();

    expect(settings, 1);
  });

  testWidgets('sin sesión no muestra "Cerrar sesión" (HU-01)', (tester) async {
    await pumpMore(tester);

    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets('con sesión, tocar "Cerrar sesión" dispara el callback (HU-06)',
      (tester) async {
    var signedOut = 0;
    await pumpMore(tester, isSignedIn: true, onSignOut: () => signedOut++);

    // Last row, below the fold in the test viewport — scroll it into view
    // before asserting/tapping.
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      100,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Cerrar sesión'), findsOneWidget);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();
    expect(signedOut, 1);
  });

  testWidgets('tocar Cuentas y Categorías enruta a sus destinos vivos',
      (tester) async {
    var accounts = 0;
    var categories = 0;
    await pumpMore(
      tester,
      onAccounts: () => accounts++,
      onCategories: () => categories++,
    );

    await tester.tap(find.text('Cuentas'));
    await tester.pump();
    await tester.tap(find.text('Categorías'));
    await tester.pump();

    expect(accounts, 1);
    expect(categories, 1);
  });

  testWidgets('tocar un destino "Próximamente" pasa su etiqueta al callback',
      (tester) async {
    final opened = <String>[];
    await pumpMore(tester, onComingSoon: opened.add);

    await tester.tap(find.text('Deudas'));
    await tester.pump();
    await tester.tap(find.text('Recurrentes'));
    await tester.pump();

    expect(opened, ['Deudas', 'Recurrentes']);
  });
}
