import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_debt_link_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bug 3 (Deudas): the "Enlazada a deuda" badge on `TransactionDetailPage`
/// used to be a pure read-only indicator with no `onTap`. This tests the
/// widget in isolation for the tap wiring itself — `transaction_detail_page_
/// test.dart` covers the router-facing call site (`entry.transaction.debtId`).
void main() {
  Future<void> pumpBadge(
    WidgetTester tester, {
    VoidCallback? onTap,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TransactionDebtLinkBadge(
              debtName: 'Crédito carro',
              onTap: onTap,
            ),
          ),
        ),
      );

  testWidgets('con onTap, tocar el badge lo dispara', (tester) async {
    var tapped = false;
    await pumpBadge(tester, onTap: () => tapped = true);

    await tester.tap(find.text('Enlazada a deuda: Crédito carro'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('sin onTap, el badge sigue renderizando el label sin fallar',
      (tester) async {
    await pumpBadge(tester);

    expect(find.text('Enlazada a deuda: Crédito carro'), findsOneWidget);
    await tester.tap(find.text('Enlazada a deuda: Crédito carro'));
    await tester.pumpAndSettle();
  });
}
