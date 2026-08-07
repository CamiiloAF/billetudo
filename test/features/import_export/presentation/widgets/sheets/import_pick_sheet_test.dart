import 'dart:async';

import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_state.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/import_pick_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockImportFlowCubit extends MockCubit<ImportFlowState> implements ImportFlowCubit {}

/// `ImportPickSheet.show` (`import_pick_sheet.dart`) drives the native file
/// picker itself before ever opening the unreadable-file sheet: it resolves
/// `ImportFlowCubit` from `getIt`, resets it, awaits `pickFile()`, and only
/// opens that sheet if the result landed on `ImportFlowRunStatus.error`. On
/// success it never opens anything — it just resolves with the cubit
/// (already parked on `ImportFlowStep.mapping`), leaving pushing
/// `ImportFlowPage` to the caller (`app_router.dart`'s `_openImportFlow`),
/// same split `restore_sheet_test.dart` covers for `RestoreSheet`.
void main() {
  late MockImportFlowCubit cubit;

  setUp(() {
    cubit = MockImportFlowCubit();
    when(() => cubit.reset()).thenReturn(null);
    when(() => cubit.close()).thenAnswer((_) async {});
    getIt.registerFactory<ImportFlowCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  Future<void> pumpTrigger(
    WidgetTester tester,
    Future<void> Function(BuildContext context) onPressed,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => onPressed(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('backing out of the native picker resolves to null and closes the cubit',
      (tester) async {
    when(() => cubit.state).thenReturn(const ImportFlowState());
    whenListen(cubit, const Stream<ImportFlowState>.empty());
    when(() => cubit.pickFile()).thenAnswer((_) async {});

    ImportFlowCubit? result;
    var resolved = false;
    await pumpTrigger(tester, (context) async {
      result = await ImportPickSheet.show(context);
      resolved = true;
    });
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(result, isNull);
    verify(() => cubit.reset()).called(1);
    verify(() => cubit.pickFile()).called(1);
    verify(() => cubit.close()).called(1);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('a file that parses resolves to the cubit without opening any sheet',
      (tester) async {
    when(() => cubit.state).thenReturn(const ImportFlowState(step: ImportFlowStep.mapping));
    whenListen(cubit, const Stream<ImportFlowState>.empty());
    when(() => cubit.pickFile()).thenAnswer((_) async {});

    ImportFlowCubit? result;
    var resolved = false;
    await pumpTrigger(tester, (context) async {
      result = await ImportPickSheet.show(context);
      resolved = true;
    });
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(result, same(cubit));
    verify(() => cubit.pickFile()).called(1);
    // The caller (`app_router.dart`'s `_openImportFlow`) owns closing this
    // cubit once the pushed wizard route pops — `.show` never does it itself
    // on a success path.
    verifyNever(() => cubit.close());
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('a file that fails to parse opens the error sheet', (tester) async {
    when(() => cubit.state).thenReturn(const ImportFlowState(runStatus: ImportFlowRunStatus.error));
    whenListen(cubit, const Stream<ImportFlowState>.empty());
    when(() => cubit.pickFile()).thenAnswer((_) async {});

    await pumpTrigger(tester, ImportPickSheet.show);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos leer este archivo'), findsOneWidget);
    expect(find.text('Elegir otro archivo'), findsOneWidget);
  });

  testWidgets('cancelling out of the error sheet resolves to null and closes the cubit',
      (tester) async {
    when(() => cubit.state).thenReturn(const ImportFlowState(runStatus: ImportFlowRunStatus.error));
    whenListen(cubit, const Stream<ImportFlowState>.empty());
    when(() => cubit.pickFile()).thenAnswer((_) async {});

    ImportFlowCubit? result;
    var resolved = false;
    await pumpTrigger(tester, (context) async {
      result = await ImportPickSheet.show(context);
      resolved = true;
    });
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(result, isNull);
    verify(() => cubit.close()).called(1);
  });

  testWidgets('retrying from the error sheet reuses the same cubit', (tester) async {
    when(() => cubit.state).thenReturn(const ImportFlowState(runStatus: ImportFlowRunStatus.error));
    whenListen(cubit, const Stream<ImportFlowState>.empty());
    when(() => cubit.pickFile()).thenAnswer((_) async {});

    await pumpTrigger(tester, ImportPickSheet.show);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elegir otro archivo'));
    await tester.pumpAndSettle();

    // The error sheet's action is wired straight to `cubit.pickFile()` —
    // same entry point `.show` itself used, no intermediate sheet to land on
    // in between (`io_error_view.dart`'s doc comment).
    verify(() => cubit.pickFile()).called(2);
  });

  testWidgets(
      'a retry that parses closes the error sheet and resolves to the cubit',
      (tester) async {
    final controller = StreamController<ImportFlowState>.broadcast();
    addTearDown(controller.close);
    const errorState = ImportFlowState(runStatus: ImportFlowRunStatus.error);
    when(() => cubit.state).thenReturn(errorState);
    whenListen(cubit, controller.stream);
    var pickFileCalls = 0;
    when(() => cubit.pickFile()).thenAnswer((_) async {
      pickFileCalls += 1;
      // First call (the initial pick, inside `.show` before the sheet even
      // opens) stays on the error state; only the retry from inside the
      // already-open sheet parses successfully.
      if (pickFileCalls < 2) {
        return;
      }
      const parsed = ImportFlowState(step: ImportFlowStep.mapping);
      when(() => cubit.state).thenReturn(parsed);
      controller.add(parsed);
    });

    ImportFlowCubit? result;
    var resolved = false;
    await pumpTrigger(tester, (context) async {
      result = await ImportPickSheet.show(context);
      resolved = true;
    });
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elegir otro archivo'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(result, same(cubit));
    expect(find.byType(BottomSheet), findsNothing);
    verifyNever(() => cubit.close());
  });
}
