import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/transactions/presentation/widgets/movements_balance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../accounts/account_fixtures.dart';
import '../../../categories/presentation/widgets/pump_widget.dart';

void main() {
  // A name long enough to force a second line at any realistic card width, so
  // the "never truncated to one line" guarantee is exercised for real (Pencil
  // never renders ellipsis — this is what the mock cannot show).
  const longName = 'Cuenta de ahorros Bancolombia Empresarial Premium';

  Text nameTextOf(WidgetTester tester, String name) =>
      tester.widget<Text>(find.text(name));

  testWidgets(
    'plain account name wraps to two lines and is never forced to one',
    (tester) async {
      final entry = buildAccountWithBalance(
        account: buildAccount(id: 'a1', name: longName, type: AccountType.bank),
        balanceMinor: 1034930200,
      );
      await tester.pumpAppWidget(
        MovementsBalanceCard(entry: entry, onOpenAccount: (_) {}),
      );

      expect(tester.takeException(), isNull);
      expect(nameTextOf(tester, longName).maxLines, 2);
    },
  );

  testWidgets(
    'plain account shows the labelled "Saldo" figure, not a hero amount',
    (tester) async {
      final entry = buildAccountWithBalance(
        account:
            buildAccount(id: 'a1', name: 'Bancolombia', type: AccountType.bank),
        balanceMinor: 1034930200,
      );
      await tester.pumpAppWidget(
        MovementsBalanceCard(entry: entry, onOpenAccount: (_) {}),
      );

      expect(find.byType(MovementsBalanceCardSimple), findsOneWidget);
      // The mirrored "Saldo" block: a small label + its figure, the same
      // MovementsBalanceCardFigure the credit variant uses (A2). The old hero
      // had no label at all.
      expect(find.text('Saldo'), findsOneWidget);
      expect(find.byType(MovementsBalanceCardFigure), findsOneWidget);
      expect(find.text(r'$10.349.302'), findsOneWidget);
    },
  );

  testWidgets(
    'credit card variant is unchanged: usage bar plus Deuda/Cupo figures',
    (tester) async {
      final entry = buildAccountWithBalance(
        account: buildCard(
            id: 'a3', name: 'Tarjeta Visa', creditLimitMinor: 300000000),
        balanceMinor: -68000000,
      );
      await tester.pumpAppWidget(
        MovementsBalanceCard(entry: entry, onOpenAccount: (_) {}),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(MovementsBalanceCardCredit), findsOneWidget);
      expect(find.byType(MovementsBalanceCardSimple), findsNothing);
      // Structure intact: the two labelled figures still there.
      expect(find.text('Deuda actual'), findsOneWidget);
      expect(find.text('Cupo disponible'), findsOneWidget);
      expect(find.text(r'$680.000'), findsOneWidget);
      expect(find.text(r'$2.320.000'), findsOneWidget);
    },
  );

  testWidgets(
    'a long credit-card name wraps to two lines without overflowing the card',
    (tester) async {
      final entry = buildAccountWithBalance(
        account:
            buildCard(id: 'a3', name: longName, creditLimitMinor: 300000000),
        balanceMinor: -68000000,
      );
      // Constrain to the real card width so the name genuinely wraps.
      await tester.pumpAppWidget(
        Center(
          child: SizedBox(
            width: 320,
            child: MovementsBalanceCard(entry: entry, onOpenAccount: (_) {}),
          ),
        ),
      );

      // The taller variant with a two-line name must fit the fixed height —
      // no RenderFlex overflow.
      expect(tester.takeException(), isNull);
      expect(nameTextOf(tester, longName).maxLines, 2);
    },
  );

  testWidgets('a negative plain balance renders in the expense colour', (
    tester,
  ) async {
    final entry = buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Sobregiro', type: AccountType.bank),
      balanceMinor: -1500000,
    );
    await tester.pumpAppWidget(
      MovementsBalanceCard(entry: entry, onOpenAccount: (_) {}),
    );

    final figure = tester.widget<MovementsBalanceCardFigure>(
      find.byType(MovementsBalanceCardFigure),
    );
    expect(figure.color, AppTheme.light().extension<AppColors>()!.expenseText);
  });
}
