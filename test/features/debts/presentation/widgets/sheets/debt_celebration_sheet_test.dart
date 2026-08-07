import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_detail_state.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_celebration_sheet.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_celebration_stat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../debts_presentation_fixtures.dart';

/// The felicitación sheet (extension, HU-07): fires when a debt's balance
/// crosses to settled. Copy and stat labels change by `direction`
/// (iOwe/owedToMe); "Ahora no"/"Completar" resolve `false`/`true`.
void main() {
  bool? result;

  DebtSettledCelebration celebrationFor(DebtDirection direction) =>
      DebtSettledCelebration(
        debt: buildDebt(
          name: 'Crédito vehicular',
          direction: direction,
          createdAt: DateTime(2026, 1, 1),
        ),
        totalPaidMinor: 4200000,
        settledAt: DateTime(2026, 7, 1),
      );

  Future<void> pumpAndOpen(
    WidgetTester tester,
    DebtSettledCelebration celebration,
  ) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await DebtCelebrationSheet.show(
                  context,
                  celebration: celebration,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'iOwe copy: title, message with the debt name, and the '
      '"Total pagado" stat label', (tester) async {
    await pumpAndOpen(tester, celebrationFor(DebtDirection.iOwe));

    expect(find.text('¡Felicidades! Ya no debes nada'), findsOneWidget);
    expect(find.textContaining('Terminaste de pagar Crédito vehicular'),
        findsOneWidget);
    expect(find.text('Total pagado'), findsOneWidget);
    expect(find.byType(DebtCelebrationStat), findsNWidgets(2));
  });

  testWidgets(
      'owedToMe copy: title, message, and the "Total cobrado" stat '
      'label', (tester) async {
    await pumpAndOpen(tester, celebrationFor(DebtDirection.owedToMe));

    expect(find.text('¡Felicidades! Ya no te deben nada'), findsOneWidget);
    expect(find.textContaining('Terminaste de cobrar Crédito vehicular'),
        findsOneWidget);
    expect(find.text('Total cobrado'), findsOneWidget);
  });

  testWidgets('tapping "Ahora no" pops with false', (tester) async {
    await pumpAndOpen(tester, celebrationFor(DebtDirection.iOwe));

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(result, false);
  });

  testWidgets('tapping "Completar" pops with true', (tester) async {
    await pumpAndOpen(tester, celebrationFor(DebtDirection.iOwe));

    await tester.tap(find.text('Completar'));
    await tester.pumpAndSettle();

    expect(result, true);
  });
}
