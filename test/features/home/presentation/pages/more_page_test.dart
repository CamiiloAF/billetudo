import 'package:billetudo/core/widgets/coming_soon_badge.dart';
import 'package:billetudo/features/home/presentation/pages/more_page.dart';
import 'package:billetudo/features/home/presentation/widgets/more_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/pump_widget.dart';

void main() {
  Future<void> pumpMore(
    WidgetTester tester, {
    VoidCallback? onAccounts,
    VoidCallback? onCategories,
    VoidCallback? onDebts,
    VoidCallback? onScheduledPayments,
    VoidCallback? onGoals,
    VoidCallback? onReports,
    ValueChanged<String>? onComingSoon,
    VoidCallback? onSettings,
    VoidCallback? onSignOut,
    bool isSignedIn = false,
  }) =>
      tester.pumpHomeWidget(
        MorePage(
          onOpenAccounts: onAccounts ?? () {},
          onOpenCategories: onCategories ?? () {},
          onOpenDebts: onDebts ?? () {},
          onOpenScheduledPayments: onScheduledPayments ?? () {},
          onOpenGoals: onGoals ?? () {},
          onOpenReports: onReports ?? () {},
          onOpenComingSoon: onComingSoon ?? (_) {},
          onOpenSettings: onSettings ?? () {},
          isSignedIn: isSignedIn,
          onSignOut: onSignOut ?? () {},
        ),
        wrapInScaffold: false,
      );

  testWidgets('lista todos los destinos de Nivel 0 (HU-01)', (tester) async {
    await pumpMore(tester);

    // Eight rows no longer fit the test viewport, so the ListView lazily
    // builds them — scroll each label into view before asserting it exists.
    for (final label in [
      'Cuentas',
      'Categorías',
      'Deudas',
      'Pagos programados',
      'Metas',
      'Gráficas e informes',
      'Importar y exportar',
      'Ajustes',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        100,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets(
      'Cuentas, Categorías, Deudas, Pagos programados, Metas, Gráficas e '
      'informes y Ajustes están vivas (sin badge Próximamente)',
      (tester) async {
    await pumpMore(tester);

    // Scroll every row into the lazy ListView's viewport before counting
    // badges, otherwise unbuilt rows below the fold would undercount.
    await tester.scrollUntilVisible(
      find.text('Ajustes'),
      100,
      scrollable: find.byType(Scrollable),
    );

    // Seven live rows, one not-yet-built one carrying the badge (Importar y
    // exportar).
    expect(find.byType(ComingSoonBadge), findsOneWidget);

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
    expect(badgeOf('Deudas'), isNull);
    expect(badgeOf('Pagos programados'), isNull);
    expect(badgeOf('Metas'), isNull);
    expect(badgeOf('Gráficas e informes'), isNull);
    expect(badgeOf('Ajustes'), isNull);
  });

  testWidgets('tocar Ajustes enruta a Ajustes', (tester) async {
    var settings = 0;
    await pumpMore(tester, onSettings: () => settings++);

    // The left-aligned root-tab header pushes the last rows below the fold in
    // the test viewport — scroll "Ajustes" into view before tapping.
    await tester.scrollUntilVisible(
      find.text('Ajustes'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.text('Ajustes'));
    await tester.pump();

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
    // before asserting/tapping. The row grew taller once its description
    // moved to its own line, so scrollUntilVisible alone can leave it right
    // at the viewport edge (fails hit-testing) — ensureVisible settles it.
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.pump();
    expect(find.text('Cerrar sesión'), findsOneWidget);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();
    expect(signedOut, 1);
  });

  testWidgets(
      'tocar Cuentas, Categorías, Deudas, Pagos programados y Metas enruta a '
      'sus destinos vivos', (tester) async {
    var accounts = 0;
    var categories = 0;
    var debts = 0;
    var scheduledPayments = 0;
    var goals = 0;
    await pumpMore(
      tester,
      onAccounts: () => accounts++,
      onCategories: () => categories++,
      onDebts: () => debts++,
      onScheduledPayments: () => scheduledPayments++,
      onGoals: () => goals++,
    );

    await tester.tap(find.text('Cuentas'));
    await tester.pump();
    await tester.tap(find.text('Categorías'));
    await tester.pump();
    await tester.tap(find.text('Deudas'));
    await tester.pump();
    await tester.tap(find.text('Pagos programados'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Metas'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Metas'));
    await tester.pump();

    expect(accounts, 1);
    expect(categories, 1);
    expect(debts, 1);
    expect(scheduledPayments, 1);
    expect(goals, 1);
  });

  testWidgets('tocar un destino "Próximamente" pasa su etiqueta al callback',
      (tester) async {
    final opened = <String>[];
    await pumpMore(tester, onComingSoon: opened.add);

    // Now the second-to-last row (after "Gráficas e informes" was added
    // above it): scrollUntilVisible alone can leave it right at the
    // viewport edge (fails hit-testing) — ensureVisible settles it, same
    // fix as "Cerrar sesión" below.
    await tester.scrollUntilVisible(
      find.text('Importar y exportar'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.text('Importar y exportar'));
    await tester.pump();
    await tester.tap(find.text('Importar y exportar'));
    await tester.pump();

    expect(opened, ['Importar y exportar']);
  });

  testWidgets('tocar Gráficas e informes enruta a la feature real',
      (tester) async {
    var reports = 0;
    await pumpMore(tester, onReports: () => reports++);

    await tester.scrollUntilVisible(
      find.text('Gráficas e informes'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Gráficas e informes'));
    await tester.pump();

    expect(reports, 1);
  });
}
