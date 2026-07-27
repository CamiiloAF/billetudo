import 'package:billetudo/core/bootstrap/app_bootstrap_gate.dart';
import 'package:billetudo/core/bootstrap/first_launch_offline_cubit.dart';
import 'package:billetudo/core/bootstrap/first_launch_offline_gate.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/usecases/seed_default_categories.dart';
import 'package:billetudo/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSeedDefaultCategories extends Mock implements SeedDefaultCategories {}

void main() {
  testWidgets(
      'muestra el splash mientras init() corre, luego cambia al builder '
      'real cuando resuelve', (tester) async {
    final completer = Future<Widget Function()>.delayed(
      const Duration(milliseconds: 10),
      () => () => const Directionality(
            textDirection: TextDirection.ltr,
            child: Text('app real'),
          ),
    );

    await tester.pumpWidget(AppBootstrapGate(init: () => completer));

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('app real'), findsNothing);

    // `SplashPage` hosts an indeterminate `CircularProgressIndicator`, so
    // `pumpAndSettle` would never return (its animation never stops):
    // advance time manually instead, past the delayed `init()` and past the
    // `setState` frame it triggers.
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();

    expect(find.text('app real'), findsOneWidget);
    expect(find.byType(SplashPage), findsNothing);
  });

  testWidgets(
      'cuando init() resuelve a un builder de FirstLaunchOfflineGate '
      '(seed falló por NetworkFailure en el primer arranque), lo muestra '
      'en vez de la app real hasta que un retry siembra con éxito — el '
      'mismo camino que bootstrap() toma en ese caso', (tester) async {
    final seedDefaultCategories = MockSeedDefaultCategories();
    when(seedDefaultCategories.call).thenAnswer((_) async => const Right(unit));
    getIt.registerFactory<FirstLaunchOfflineCubit>(
      () => FirstLaunchOfflineCubit(seedDefaultCategories),
    );
    addTearDown(getIt.reset);

    Widget realBuilder() => const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('app real'),
        );

    final completer = Future<Widget Function()>.delayed(
      const Duration(milliseconds: 10),
      () => () => FirstLaunchOfflineGate(builder: realBuilder),
    );

    await tester.pumpWidget(AppBootstrapGate(init: () => completer));

    expect(find.byType(SplashPage), findsOneWidget);

    // Past the delayed `init()` and the `setState` frame that swaps in
    // `FirstLaunchOfflineGate` — same manual-time-advance reasoning as
    // above: the splash's spinner is indeterminate.
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();

    expect(find.byType(SplashPage), findsNothing);
    expect(find.text('Connect to continue'), findsOneWidget);
    expect(find.text('app real'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('app real'), findsOneWidget);
    expect(find.text('Connect to continue'), findsNothing);
  });
}
