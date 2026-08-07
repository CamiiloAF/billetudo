import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/import_export/domain/entities/backup_header.dart';
import 'package:billetudo/features/import_export/presentation/cubit/restore_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/restore_state.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/restore_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRestoreCubit extends MockCubit<RestoreState> implements RestoreCubit {}

/// `RestoreSheet.show` (`restore_sheet.dart`) drives the native file picker
/// itself before ever opening the modal sheet: it resolves `RestoreCubit`
/// from `getIt`, resets it, awaits `pickFile()`, and only opens the sheet
/// if that landed on a step past `RestoreStep.pickFile`. Same shape
/// `import_flow_page_test.dart` already covers for `ImportFlowPage`'s entry
/// step, but here the branching lives in the static `.show` function
/// itself, not in a `StatefulWidget`'s `initState`.
void main() {
  late MockRestoreCubit cubit;

  final header = BackupHeader(
    formatVersion: 1,
    schemaVersion: 9,
    appVersion: '1.4.0',
    createdAt: DateTime(2026, 7, 15),
    rowCountsByTable: const {},
  );

  setUp(() {
    cubit = MockRestoreCubit();
    when(() => cubit.reset()).thenReturn(null);
    when(() => cubit.close()).thenAnswer((_) async {});
    getIt.registerFactory<RestoreCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  Future<void> pumpTrigger(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => RestoreSheet.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('backing out of the native picker leaves nothing mounted', (tester) async {
    when(() => cubit.state).thenReturn(const RestoreState());
    when(() => cubit.pickFile()).thenAnswer((_) async {});

    await pumpTrigger(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.byType(RestoreSheetBody), findsNothing);
    verify(() => cubit.reset()).called(1);
    verify(() => cubit.pickFile()).called(1);
    // Nothing to show — the flow closes the cubit it just created instead
    // of leaving it (and a dead sheet) mounted.
    verify(() => cubit.close()).called(1);
  });

  testWidgets('picking a file opens the sheet and defers closing the cubit',
      (tester) async {
    when(() => cubit.state).thenReturn(
      RestoreState(step: RestoreStep.summary, header: header),
    );
    when(() => cubit.pickFile()).thenAnswer((_) async {});

    await pumpTrigger(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.byType(RestoreSheetBody), findsOneWidget);
    verify(() => cubit.pickFile()).called(1);
    // The sheet is still open (never dismissed in this test) — `.show`
    // awaits the modal route before closing the cubit, so closing it this
    // early would tear down state the still-visible sheet depends on.
    verifyNever(() => cubit.close());
  });

  testWidgets('retrying from the error step reopens the native picker',
      (tester) async {
    when(() => cubit.state).thenReturn(const RestoreState(step: RestoreStep.error));
    when(() => cubit.pickFile()).thenAnswer((_) async {});

    await pumpTrigger(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // The error step's action is wired straight to `cubit.pickFile()` — the
    // same entry point `.show` itself used, no intermediate "choose a file"
    // sheet to land on (`io_error_view.dart`'s doc comment).
    expect(find.text('Elegir otro archivo'), findsOneWidget);
    await tester.tap(find.text('Elegir otro archivo'));
    await tester.pumpAndSettle();

    verify(() => cubit.pickFile()).called(2);
  });
}
