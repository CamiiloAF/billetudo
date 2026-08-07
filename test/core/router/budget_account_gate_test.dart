import 'dart:async';

import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/domain/usecases/has_any_active_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_active_accounts_count.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_copy.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gated_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockHasAnyActiveAccount extends Mock implements HasAnyActiveAccount {}

class MockWatchActiveAccountsCount extends Mock
    implements WatchActiveAccountsCount {}

/// `15-gate-cuenta.md` HU-03: crear presupuesto exige cuenta desde el
/// 2026-08-06 (decisión de producto revertida), incluido el alcance "Todo"
/// — `app_router.dart` envuelve `/presupuestos/nuevo` en
/// `AccountGatedRoute(surface: AccountGateSurface.budget)`, el mismo patrón
/// que `AppRoutes.newScheduledPayment`/`AppRoutes.newTransaction`. Este test
/// pin-ea esa decisión: la ruta de creación de presupuesto no debe volver a
/// quedar accesible sin cuenta, y su copy debe ser la de `flt4U`, no la
/// genérica de movimiento.
void main() {
  late StreamController<bool> hasAnyController;

  setUp(() {
    hasAnyController = StreamController<bool>.broadcast();
    final hasAnyActiveAccount = MockHasAnyActiveAccount();
    when(hasAnyActiveAccount.call).thenAnswer((_) => hasAnyController.stream);
    getIt.registerFactory<HasAnyActiveAccount>(() => hasAnyActiveAccount);
    final watchActiveAccountsCount = MockWatchActiveAccountsCount();
    when(watchActiveAccountsCount.call).thenAnswer(
      (_) => hasAnyController.stream.map((hasAny) => hasAny ? 1 : 0),
    );
    getIt.registerFactory<WatchActiveAccountsCount>(
      () => watchActiveAccountsCount,
    );
  });

  tearDown(getIt.reset);
  tearDown(() => hasAnyController.close());

  testWidgets(
      'crear presupuesto sin cuentas activas muestra el puente con el copy '
      'de AccountGateSurface.budget, no monta el formulario',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/presupuestos',
      routes: [
        GoRoute(
          path: '/presupuestos',
          builder: (context, state) =>
              const Scaffold(body: Text('presupuestos')),
          routes: [
            GoRoute(
              path: 'nuevo',
              // Same wrapper `app_router.dart` uses for
              // `AppRoutes.newBudget`.
              builder: (context, state) => AccountGatedRoute(
                surface: AccountGateSurface.budget,
                builder: (context) =>
                    const Scaffold(body: Text('form-mounted')),
              ),
            ),
          ],
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

    unawaited(router.push<void>(AppRoutes.newBudget));
    await tester.pump();
    hasAnyController.add(false);
    await tester.pumpAndSettle();

    expect(find.byType(AccountGateBridgeSheet), findsOneWidget);
    expect(find.text('form-mounted'), findsNothing);

    final context = tester.element(find.byType(AccountGateBridgeSheet));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.accountGateBudgetTitle), findsOneWidget);
    expect(find.text(l10n.accountGateBudgetMessage), findsOneWidget);
  });

  testWidgets(
      'con al menos una cuenta activa, crear presupuesto monta el '
      'formulario directo, sin puente', (tester) async {
    final router = GoRouter(
      initialLocation: '/presupuestos',
      routes: [
        GoRoute(
          path: '/presupuestos',
          builder: (context, state) =>
              const Scaffold(body: Text('presupuestos')),
          routes: [
            GoRoute(
              path: 'nuevo',
              builder: (context, state) => AccountGatedRoute(
                surface: AccountGateSurface.budget,
                builder: (context) =>
                    const Scaffold(body: Text('form-mounted')),
              ),
            ),
          ],
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

    unawaited(router.push<void>(AppRoutes.newBudget));
    await tester.pump();
    hasAnyController.add(true);
    await tester.pumpAndSettle();

    expect(find.byType(AccountGateBridgeSheet), findsNothing);
    expect(find.text('form-mounted'), findsOneWidget);
  });
}
