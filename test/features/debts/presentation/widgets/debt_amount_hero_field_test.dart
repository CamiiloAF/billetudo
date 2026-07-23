import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_amount_hero_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers Deudas fixes 1a (a single `$`, never a doubled `$$0`) and 1b (the
/// field always accepts two decimals, COP included, shown only once the user
/// types the comma — the Transacciones money-entry pattern).
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required String currency,
    required ValueChanged<int> onChanged,
    int initialAmountMinor = 0,
    bool autofocus = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DebtAmountHeroField(
            label: 'Saldo de apertura',
            currency: currency,
            initialAmountMinor: initialAmountMinor,
            onChanged: onChanged,
            autofocus: autofocus,
            fieldKey: const ValueKey('hero'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('1a: enfocado y vacío muestra un solo "\$" (prefijo + hint "0")',
      (tester) async {
    await pump(tester, currency: 'COP', onChanged: (_) {}, autofocus: true);

    // The hint is just '0' now; the '$' comes only from the prefix. So the
    // doubled "$$0" the bug produced must not exist, and a lone "0" hint does.
    expect(find.text(r'$0'), findsNothing);
    expect(find.text(r'$$0'), findsNothing);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('1b: COP acepta dos decimales — "150000" es 15000000 en centavos',
      (tester) async {
    int? reported;
    await pump(tester, currency: 'COP', onChanged: (v) => reported = v);

    await tester.enterText(find.byKey(const ValueKey('hero')), '150000');
    await tester.pump();

    expect(reported, 15000000);
  });

  testWidgets('1b: COP con coma — "150000,50" es 15000050 en centavos',
      (tester) async {
    int? reported;
    await pump(tester, currency: 'COP', onChanged: (v) => reported = v);

    await tester.enterText(find.byKey(const ValueKey('hero')), '150000,50');
    await tester.pump();

    expect(reported, 15000050);
  });

  testWidgets('1b: un saldo COP entero se siembra sin decimales', (tester) async {
    await pump(
      tester,
      currency: 'COP',
      onChanged: (_) {},
      initialAmountMinor: 15000000,
    );

    expect(find.text('150.000'), findsOneWidget);
    expect(find.text('150.000,00'), findsNothing);
  });

  testWidgets('1b: un saldo COP con centavos se siembra mostrándolos',
      (tester) async {
    await pump(
      tester,
      currency: 'COP',
      onChanged: (_) {},
      initialAmountMinor: 15000050,
    );

    expect(find.text('150.000,50'), findsOneWidget);
  });
}
