import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/domain/usecases/has_any_active_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_active_accounts_count.dart';
import 'package:billetudo/features/accounts/presentation/utils/show_account_gate_if_needed.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockHasAnyActiveAccount extends Mock implements HasAnyActiveAccount {}

class MockWatchActiveAccountsCount extends Mock
    implements WatchActiveAccountsCount {}

/// `15-gate-cuenta.md` HU-02: transferencia needs **two** active accounts,
/// not one, so with 0 the bridge chains "0 cuentas" (`XYfSq`) → create →
/// "segunda cuenta" (`goGwA`) → create → proceed, re-reading the live count
/// on every loop instead of a bespoke state machine.
void main() {
  // A mutable "current count" instead of a `StreamController`:
  // `showAccountGateIfNeeded`'s loop calls `watchActiveAccountsCount()` and
  // reads `.first` on *every* iteration, so each call gets a fresh
  // single-value stream reflecting whatever this test has set at that point
  // — no broadcast-vs-single-subscription timing to fight.
  late int currentCount;

  setUp(() {
    currentCount = 0;
    final hasAnyActiveAccount = MockHasAnyActiveAccount();
    when(hasAnyActiveAccount.call)
        .thenAnswer((_) => Stream.value(currentCount > 0));
    getIt.registerFactory<HasAnyActiveAccount>(() => hasAnyActiveAccount);
    final watchActiveAccountsCount = MockWatchActiveAccountsCount();
    when(watchActiveAccountsCount.call)
        .thenAnswer((_) => Stream.value(currentCount));
    getIt.registerFactory<WatchActiveAccountsCount>(
      () => watchActiveAccountsCount,
    );
  });

  tearDown(getIt.reset);

  Future<GoRouter> pumpApp(WidgetTester tester, {bool? Function()? onDone}) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final proceeded = await showAccountGateIfNeeded(
                  context,
                  AccountGateSurface.transfer,
                );
                onDone?.call();
                if (proceeded) {
                  // no-op: caller would now open the transfer form.
                }
              },
              child: const Text('start-transfer'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.newAccount,
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('simulate-create'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pump();
    return router;
  }

  testWidgets(
      'con 0 cuentas: muestra el copy de 0 cuentas (XYfSq), no el de '
      'segunda cuenta', (tester) async {
    await pumpApp(tester);
    currentCount = 0;
    await tester.pump();

    await tester.tap(find.text('start-transfer'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AccountGateBridgeSheet));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.accountGateTransferZeroTitle), findsOneWidget);
    expect(find.text(l10n.accountGateTransferOneTitle), findsNothing);
  });

  testWidgets(
      'con exactamente 1 cuenta: muestra el copy de segunda cuenta (goGwA)',
      (tester) async {
    await pumpApp(tester);
    currentCount = 1;
    await tester.pump();

    await tester.tap(find.text('start-transfer'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AccountGateBridgeSheet));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.accountGateTransferOneTitle), findsOneWidget);
    expect(find.text(l10n.accountGateTransferZeroTitle), findsNothing);
  });

  testWidgets('con 2 o más cuentas: procede directo, sin puente',
      (tester) async {
    var proceeded = false;
    await pumpApp(tester, onDone: () {
      proceeded = true;
      return null;
    });
    currentCount = 2;
    await tester.pump();

    await tester.tap(find.text('start-transfer'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountGateBridgeSheet), findsNothing);
    expect(proceeded, isTrue);
  });

  testWidgets(
      'encadenamiento HU-02: 0 cuentas -> XYfSq -> crear -> 1 cuenta -> '
      'goGwA -> crear -> 2 cuentas -> procede — 2 hojas, no 3',
      (tester) async {
    await pumpApp(tester);
    currentCount = 0;
    await tester.pump();

    await tester.tap(find.text('start-transfer'));
    await tester.pumpAndSettle();

    var context = tester.element(find.byType(AccountGateBridgeSheet));
    var l10n = AppLocalizations.of(context);
    expect(find.text(l10n.accountGateTransferZeroTitle), findsOneWidget);

    // Accept: opens the account form (HU-01 of `01-cuentas.md`).
    await tester.tap(find.text(l10n.accountGateCreateAccount));
    await tester.pumpAndSettle();
    expect(find.text('simulate-create'), findsOneWidget);

    // Simulate the first account being created (repository catches up
    // *before* the form pops, exactly like the real gate loop expects),
    // then the form popping.
    currentCount = 1;
    await tester.tap(find.text('simulate-create'));
    await tester.pumpAndSettle();

    // Same loop, re-read count: now shows the "segunda cuenta" copy.
    context = tester.element(find.byType(AccountGateBridgeSheet));
    l10n = AppLocalizations.of(context);
    expect(find.text(l10n.accountGateTransferOneTitle), findsOneWidget);
    expect(find.text(l10n.accountGateTransferZeroTitle), findsNothing);

    await tester.tap(find.text(l10n.accountGateCreateAccount));
    await tester.pumpAndSettle();
    expect(find.text('simulate-create'), findsOneWidget);

    currentCount = 2;
    await tester.tap(find.text('simulate-create'));
    await tester.pumpAndSettle();

    // Requirement met: no third bridge sheet.
    expect(find.byType(AccountGateBridgeSheet), findsNothing);
  });
}
