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

/// `15-gate-cuenta.md` HU-04: a direct/deep-linked visit to a gated route
/// must get the same bridge a FAB tap gets instead of an unusable form —
/// [AccountGatedRoute] is what every such `GoRoute.builder` wraps its page
/// in.
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

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/gated',
          builder: (context, state) => AccountGatedRoute(
            surface: AccountGateSurface.movement,
            builder: (context) =>
                const Scaffold(body: Text('form-mounted')),
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
      'sin ninguna cuenta activa: no monta el builder, muestra el puente',
      (tester) async {
    final router = await pumpApp(tester);
    unawaited(router.push<void>('/gated'));
    await tester.pump();
    hasAnyController.add(false);
    await tester.pumpAndSettle();

    expect(find.byType(AccountGateBridgeSheet), findsOneWidget);
    expect(find.text('form-mounted'), findsNothing);
  });

  testWidgets(
      'cancelar el puente ("Ahora no") vuelve a donde estaba, no monta el '
      'builder', (tester) async {
    final router = await pumpApp(tester);
    unawaited(router.push<void>('/gated'));
    await tester.pump();
    hasAnyController.add(false);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AccountGateBridgeSheet));
    final l10n = AppLocalizations.of(context);
    await tester.tap(find.text(l10n.accountGateNotNow));
    await tester.pumpAndSettle();

    expect(find.text('form-mounted'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets(
      'con al menos una cuenta activa desde el inicio: monta el builder '
      'directo, sin puente', (tester) async {
    final router = await pumpApp(tester);
    unawaited(router.push<void>('/gated'));
    await tester.pump();
    hasAnyController.add(true);
    await tester.pumpAndSettle();

    expect(find.byType(AccountGateBridgeSheet), findsNothing);
    expect(find.text('form-mounted'), findsOneWidget);
  });

  testWidgets(
      'crear la cuenta desde el puente hace que la ruta original se abra '
      'con la cuenta ya disponible (HU-04/HU-09), sin volver a home',
      (tester) async {
    final router = await pumpApp(tester);
    unawaited(router.push<void>('/gated'));
    await tester.pump();
    hasAnyController.add(false);
    await tester.pumpAndSettle();

    final bridgeContext = tester.element(find.byType(AccountGateBridgeSheet));
    final bridgeL10n = AppLocalizations.of(bridgeContext);
    await tester.tap(find.text(bridgeL10n.accountGateCreateAccount));
    await tester.pumpAndSettle();

    // The account form (HU-01 of `01-cuentas.md`) is up.
    expect(find.text('simulate-create'), findsOneWidget);

    // Simulate the account form popping after a successful save, then the
    // repository stream catching up with the freshly created account.
    await tester.tap(find.text('simulate-create'));
    await tester.pump();
    hasAnyController.add(true);
    await tester.pumpAndSettle();

    expect(find.byType(AccountGateBridgeSheet), findsNothing);
    expect(find.text('form-mounted'), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });
}
