import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/import_export/presentation/cubit/export_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/export_state.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/export_run_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExportCubit extends MockCubit<ExportState> implements ExportCubit {}

/// `ExportRunSheet.show` (`export_run_sheet.dart`) starts the write on the
/// cubit it's handed (already provided by `ExportPage`'s route, not resolved
/// via `getIt` — the scope form it's called from needs that same instance)
/// and opens the modal sheet on top of it.
void main() {
  late MockExportCubit cubit;

  setUp(() {
    cubit = MockExportCubit();
    when(() => cubit.confirm(language: any(named: 'language'))).thenAnswer((_) async {});
  });

  Future<void> pumpTrigger(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ExportRunSheet.show(context, cubit: cubit, language: 'es'),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('opens the sheet and starts the export write immediately', (tester) async {
    when(() => cubit.state).thenReturn(const ExportState(runStatus: ExportRunStatus.running));

    await pumpTrigger(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.byType(ExportRunSheetBody), findsOneWidget);
    verify(() => cubit.confirm(language: 'es')).called(1);
  });
}
