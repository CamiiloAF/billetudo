import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/merge_summary.dart';
import 'package:billetudo/features/auth/domain/usecases/merge_local_data.dart';
import 'package:billetudo/features/auth/presentation/cubit/merge_cubit.dart';
import 'package:billetudo/features/auth/presentation/pages/merge_confirmation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../widgets/pump_widget.dart';

class MockMergeLocalData extends Mock implements MergeLocalData {}

void main() {
  late MockMergeLocalData mergeLocalData;

  setUp(() {
    mergeLocalData = MockMergeLocalData();
  });

  Future<void> pumpMerge(WidgetTester tester, {VoidCallback? onDone}) =>
      tester.pumpAuthWidget(
        BlocProvider(
          create: (_) {
            final cubit = MergeCubit(mergeLocalData);
            unawaited(cubit.start());
            return cubit;
          },
          child: MergeConfirmationPage(onDone: onDone ?? () {}),
        ),
        wrapInScaffold: false,
      );

  testWidgets('HU-04: muestra el resumen de la fusión con sus 3 conteos',
      (tester) async {
    const summary = MergeSummary(
      accountsCount: 3,
      transactionsCount: 20,
      categoriesCount: 8,
    );
    when(() => mergeLocalData())
        .thenAnswer((_) async => const Right(summary));

    await pumpMerge(tester);
    await tester.pumpAndSettle();

    expect(find.text('Tus datos están a salvo'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Cuentas'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
  });

  testWidgets('el CTA "Ir a mis finanzas" dispara onDone', (tester) async {
    const summary = MergeSummary(
      accountsCount: 1,
      transactionsCount: 1,
      categoriesCount: 1,
    );
    when(() => mergeLocalData())
        .thenAnswer((_) async => const Right(summary));

    var done = false;
    await pumpMerge(tester, onDone: () => done = true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ir a mis finanzas'));
    await tester.pump();

    expect(done, isTrue);
  });

  testWidgets('un fallo de fusión muestra el estado de error, no crashea',
      (tester) async {
    when(() => mergeLocalData())
        .thenAnswer((_) async => const Left(NetworkFailure('offline')));

    await pumpMerge(tester);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    // HU-04's own merge-failure copy, distinct from HU-07's delete-account
    // error ("No pudimos eliminar tu cuenta") — see `authMergeErrorTitle`/
    // `authMergeErrorMessage`.
    expect(find.text('No pudimos fusionar tus datos'), findsOneWidget);
    expect(
      find.text(
        'Tus datos siguen a salvo en este dispositivo. '
        'Intenta de nuevo cuando tengas conexión.',
      ),
      findsOneWidget,
    );
  });
}
