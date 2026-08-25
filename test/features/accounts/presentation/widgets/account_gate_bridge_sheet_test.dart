import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

void main() {
  group('AccountGateCopy.resolve', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = lookupAppLocalizations(const Locale('es'));
    });

    test('cada superficie de HU-03 tiene su propio copy', () {
      final movement = AccountGateCopy.resolve(
        l10n,
        AccountGateSurface.movement,
        currentCount: 0,
      );
      expect(movement.title, l10n.accountGateMovementTitle);
      expect(movement.message, l10n.accountGateMovementMessage);

      final scheduledPayment = AccountGateCopy.resolve(
        l10n,
        AccountGateSurface.scheduledPayment,
        currentCount: 0,
      );
      expect(scheduledPayment.title, l10n.accountGateScheduledPaymentTitle);

      final debtCash = AccountGateCopy.resolve(
        l10n,
        AccountGateSurface.debtCash,
        currentCount: 0,
      );
      expect(debtCash.title, l10n.accountGateDebtCashTitle);

      final goalMovement = AccountGateCopy.resolve(
        l10n,
        AccountGateSurface.goalMovement,
        currentCount: 0,
      );
      expect(goalMovement.title, l10n.accountGateGoalMovementTitle);

      final linkMovement = AccountGateCopy.resolve(
        l10n,
        AccountGateSurface.linkMovement,
        currentCount: 0,
      );
      expect(linkMovement.title, l10n.accountGateLinkMovementTitle);

      final budget = AccountGateCopy.resolve(
        l10n,
        AccountGateSurface.budget,
        currentCount: 0,
      );
      expect(budget.title, l10n.accountGateBudgetTitle);
      expect(budget.message, l10n.accountGateBudgetMessage);

      final goalLinkedAccount = AccountGateCopy.resolve(
        l10n,
        AccountGateSurface.goalLinkedAccount,
        currentCount: 0,
      );
      expect(goalLinkedAccount.title, l10n.accountGateGoalLinkedAccountTitle);
      expect(
        goalLinkedAccount.message,
        l10n.accountGateGoalLinkedAccountMessage,
      );
    });

    test(
        'transferencia con 0 cuentas usa XYfSq, con 1 usa goGwA — distinto '
        'copy para la misma superficie', () {
      final zero = AccountGateCopy.resolve(
        l10n,
        AccountGateSurface.transfer,
        currentCount: 0,
      );
      final one = AccountGateCopy.resolve(
        l10n,
        AccountGateSurface.transfer,
        currentCount: 1,
      );

      expect(zero.title, l10n.accountGateTransferZeroTitle);
      expect(zero.message, l10n.accountGateTransferZeroMessage);
      expect(one.title, l10n.accountGateTransferOneTitle);
      expect(one.message, l10n.accountGateTransferOneMessage);
      expect(zero.title, isNot(one.title));
    });

    test('requiredCount: 2 solo para transfer, 1 para el resto', () {
      expect(AccountGateCopy.requiredCount(AccountGateSurface.transfer), 2);
      for (final surface in AccountGateSurface.values) {
        if (surface == AccountGateSurface.transfer) {
          continue;
        }
        expect(AccountGateCopy.requiredCount(surface), 1);
      }
    });
  });

  group('AccountGateBridgeSheet', () {
    testWidgets('renderiza el icono, título y mensaje del copy dado',
        (tester) async {
      const copy = AccountGateCopy(
        icon: Icons.account_balance,
        title: 'Título de prueba',
        message: 'Mensaje de prueba',
      );
      await tester.pumpAppWidget(const AccountGateBridgeSheet(copy: copy));

      expect(find.text('Título de prueba'), findsOneWidget);
      expect(find.text('Mensaje de prueba'), findsOneWidget);
    });

    testWidgets('"Ahora no" resuelve a false — cancelar, no crear',
        (tester) async {
      bool? result;
      await tester.pumpAppWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AccountGateBridgeSheet.show(
                context,
                AccountGateCopy.resolve(
                  AppLocalizations.of(context),
                  AccountGateSurface.movement,
                  currentCount: 0,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AccountGateBridgeSheet));
      final l10n = AppLocalizations.of(context);
      await tester.tap(find.text(l10n.accountGateNotNow));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('"Crear cuenta" resuelve a true — continúa la acción',
        (tester) async {
      bool? result;
      await tester.pumpAppWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AccountGateBridgeSheet.show(
                context,
                AccountGateCopy.resolve(
                  AppLocalizations.of(context),
                  AccountGateSurface.movement,
                  currentCount: 0,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AccountGateBridgeSheet));
      final l10n = AppLocalizations.of(context);
      await tester.tap(find.text(l10n.accountGateCreateAccount));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets(
        'precedencia sobre el gate de minitutoriales: la hoja de cuenta se '
        'resuelve primero, el hook del minitutorial (aún no implementado en '
        'código) sólo se dispara después de que el usuario responde',
        (tester) async {
      // `docs/requirements/fase-1/15-gate-cuenta.md`: "si en la misma entrada
      // corresponde mostrar el puente y un minitutorial, gana el puente; el
      // tutorial espera a la siguiente visita." There is no minitutoriales
      // gate in code yet (`16-minitutoriales.md`), so this pins the ordering
      // contract any future integration must respect: whatever would decide
      // to show a minitutorial next must wait for the account gate's answer
      // instead of running concurrently with it.
      var minitutorialWouldShow = false;

      Future<void> entryPoint(BuildContext context) async {
        final proceeded = await AccountGateBridgeSheet.show(
          context,
          AccountGateCopy.resolve(
            AppLocalizations.of(context),
            AccountGateSurface.movement,
            currentCount: 0,
          ),
        );
        // Only after the account gate resolves does the (future)
        // minitutoriales hook get its turn.
        if (proceeded) {
          minitutorialWouldShow = true;
        }
      }

      await tester.pumpAppWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => entryPoint(context),
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // While the account gate sheet is open, the minitutorial has not run.
      expect(find.byType(AccountGateBridgeSheet), findsOneWidget);
      expect(minitutorialWouldShow, isFalse);

      final context = tester.element(find.byType(AccountGateBridgeSheet));
      final l10n = AppLocalizations.of(context);
      await tester.tap(find.text(l10n.accountGateCreateAccount));
      await tester.pumpAndSettle();

      // Only now, after the account gate's own answer, would the
      // minitutorial hook run.
      expect(minitutorialWouldShow, isTrue);
    });
  });
}
