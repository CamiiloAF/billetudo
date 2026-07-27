import 'package:billetudo/core/bootstrap/first_launch_offline_cubit.dart';
import 'package:billetudo/core/bootstrap/first_launch_offline_gate.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/usecases/seed_default_categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSeedDefaultCategories extends Mock implements SeedDefaultCategories {}

void main() {
  late MockSeedDefaultCategories seedDefaultCategories;

  setUp(() {
    seedDefaultCategories = MockSeedDefaultCategories();
    getIt.registerFactory<FirstLaunchOfflineCubit>(
      () => FirstLaunchOfflineCubit(seedDefaultCategories),
    );
  });

  tearDown(getIt.reset);

  testWidgets(
      'muestra la pantalla de bloqueo hasta que el retry siembra con éxito, '
      'luego muestra el builder real', (tester) async {
    when(() => seedDefaultCategories())
        .thenAnswer((_) async => const Right(unit));
    var builderCalls = 0;

    await tester.pumpWidget(
      FirstLaunchOfflineGate(
        builder: () {
          builderCalls++;
          return const Directionality(
            textDirection: TextDirection.ltr,
            child: Text('app real'),
          );
        },
      ),
    );

    expect(find.text('Connect to continue'), findsOneWidget);
    expect(find.text('app real'), findsNothing);
    expect(builderCalls, 0);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('app real'), findsOneWidget);
    expect(find.text('Connect to continue'), findsNothing);
    expect(builderCalls, 1);
  });
}
