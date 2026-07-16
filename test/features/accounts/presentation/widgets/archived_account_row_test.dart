import 'package:billetudo/features/accounts/presentation/widgets/account_card.dart';
import 'package:billetudo/features/accounts/presentation/widgets/archived_account_row.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../account_fixtures.dart';
import 'pump_widget.dart';

void main() {
  testWidgets('la tarjeta y el footer "Desarchivar" viven en un solo bloque',
      (tester) async {
    await tester.pumpAppWidget(
      ArchivedAccountRow(
        entry: buildAccountWithBalance(
          account: buildAccount(name: 'Cuenta vieja', archived: true),
          balanceMinor: 120000,
        ),
        onUnarchive: () {},
      ),
    );

    expect(find.text('Cuenta vieja'), findsOneWidget);
    expect(find.byType(AccountCard), findsOneWidget);
    expect(find.text('Desarchivar'), findsOneWidget);
  });

  testWidgets('tocar el footer desarchiva', (tester) async {
    var unarchived = false;
    await tester.pumpAppWidget(
      ArchivedAccountRow(
        entry: buildAccountWithBalance(
          account: buildAccount(archived: true),
          balanceMinor: 0,
        ),
        onUnarchive: () => unarchived = true,
      ),
    );

    await tester.tap(find.text('Desarchivar'));
    expect(unarchived, isTrue);
  });
}
