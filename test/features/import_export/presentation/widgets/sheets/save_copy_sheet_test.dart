import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/import_export/presentation/cubit/save_copy_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/save_copy_state.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/save_copy_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSaveCopyCubit extends MockCubit<SaveCopyState> implements SaveCopyCubit {}

/// `SaveCopySheet.show` (`save_copy_sheet.dart`) resolves `SaveCopyCubit`
/// from `getIt`, starts the write immediately and opens the modal sheet on
/// top of it — HU-03's whole flow is the shared progress/error pattern, so
/// unlike `RestoreSheet` there is no intermediate file-picker step to gate
/// on first.
void main() {
  late MockSaveCopyCubit cubit;

  setUp(() {
    cubit = MockSaveCopyCubit();
    when(() => cubit.start()).thenAnswer((_) async {});
    when(() => cubit.close()).thenAnswer((_) async {});
    getIt.registerFactory<SaveCopyCubit>(() => cubit);
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
            onPressed: () => SaveCopySheet.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('opens the sheet and starts the write immediately', (tester) async {
    when(() => cubit.state).thenReturn(const SaveCopyState(status: SaveCopyStatus.running));

    await pumpTrigger(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.byType(SaveCopySheetBody), findsOneWidget);
    verify(() => cubit.start()).called(1);
  });

  testWidgets(
    'show returns savedAt so the caller can update the hub without a full '
    'refresh (bug: markBackupJustSaved was never called from anywhere)',
    (tester) async {
      final savedAt = DateTime(2026, 8, 7, 10, 30);
      when(() => cubit.state).thenReturn(
        SaveCopyState(status: SaveCopyStatus.done, savedAt: savedAt),
      );

      DateTime? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await SaveCopySheet.show(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // `done` never renders — `SaveCopySheetBody`'s listener reacts to
      // `resultFilePath`, which this stubbed state does not set, so nothing
      // pops the sheet on its own here. Pop it directly to let `show`
      // resolve, same as the real flow does once the share sheet closes.
      Navigator.of(tester.element(find.byType(SaveCopySheetBody))).pop();
      await tester.pumpAndSettle();

      expect(result, savedAt);
    },
  );

  testWidgets('closes the cubit once the sheet is dismissed', (tester) async {
    when(() => cubit.state).thenReturn(const SaveCopyState(status: SaveCopyStatus.error));

    await pumpTrigger(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    verifyNever(() => cubit.close());

    // "Cancelar" on the write-failure view pops the sheet.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verify(() => cubit.close()).called(1);
  });
}
