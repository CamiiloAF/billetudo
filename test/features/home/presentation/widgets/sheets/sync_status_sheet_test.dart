import 'dart:async';

import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/sync_status_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

void main() {
  final month = DateTime(2026, 7);

  HomeState stateWith(HomeSyncStatus status) => HomeState(
        month: month,
        currentMonth: month,
        status: HomeStatus.ready,
        syncStatus: status,
      );

  Future<void> pumpSheet(
    WidgetTester tester,
    MockHomeCubit cubit,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<HomeCubit>.value(
            value: cubit,
            child: const SyncStatusSheet(),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'reactivo: pasa de "Sincronizando…" a "Todo a salvo" en sitio '
      'cuando la sync termina, sin cerrarse (bugfix item 6)', (tester) async {
    final controller = StreamController<HomeState>();
    addTearDown(controller.close);
    final cubit = MockHomeCubit();
    whenListen(
      cubit,
      controller.stream,
      initialState: stateWith(HomeSyncStatus.syncing),
    );

    await pumpSheet(tester, cubit);

    expect(find.text('Sincronizando…'), findsOneWidget);
    expect(find.text('Estamos guardando tus cambios en la nube.'),
        findsOneWidget);
    expect(find.text('Todo a salvo'), findsNothing);

    controller.add(stateWith(HomeSyncStatus.synced));
    await tester.pump();

    // Same sheet instance, content swapped in place.
    expect(find.byType(SyncStatusSheet), findsOneWidget);
    expect(find.text('Todo a salvo'), findsOneWidget);
    expect(find.text('Tu información está a salvo y sincronizada.'),
        findsOneWidget);
    expect(find.text('Sincronizando…'), findsNothing);
  });

  testWidgets('sin conexión: copy local-first, no de error', (tester) async {
    final cubit = MockHomeCubit();
    whenListen(
      cubit,
      const Stream<HomeState>.empty(),
      initialState: stateWith(HomeSyncStatus.offline),
    );

    await pumpSheet(tester, cubit);

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(
      find.text(
        'Tus datos están guardados en este dispositivo. '
        'Se sincronizarán en cuanto vuelva la conexión.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('el botón "Entendido" cierra el sheet', (tester) async {
    final cubit = MockHomeCubit();
    whenListen(
      cubit,
      const Stream<HomeState>.empty(),
      initialState: stateWith(HomeSyncStatus.synced),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => SyncStatusSheet.show(context, cubit),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Todo a salvo'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Todo a salvo'), findsNothing);
  });
}
