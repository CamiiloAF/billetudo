import 'dart:async';

import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_state.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/import_run_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockImportFlowCubit extends MockCubit<ImportFlowState> implements ImportFlowCubit {}

/// `ImportRunSheet.show` (`import_run_sheet.dart`) starts the commit on the
/// cubit it's handed (already provided by `ImportFlowPage`'s route) and
/// opens the modal sheet on top of it. Cancelling the commit rolls it back
/// to the preview step with `idle` — the sheet reacts to that transition by
/// closing itself instead of waiting for an explicit tap.
void main() {
  late MockImportFlowCubit cubit;

  setUp(() {
    cubit = MockImportFlowCubit();
    when(() => cubit.confirm(saveTemplateAs: any(named: 'saveTemplateAs')))
        .thenAnswer((_) async {});
  });

  Future<void> pumpTrigger(WidgetTester tester, {VoidCallback? onDone}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ImportRunSheet.show(
              context,
              cubit: cubit,
              onDone: onDone ?? () {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('opens the sheet and starts the commit immediately', (tester) async {
    when(() => cubit.state).thenReturn(
      const ImportFlowState(
        step: ImportFlowStep.preview,
        runStatus: ImportFlowRunStatus.committing,
      ),
    );

    await pumpTrigger(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.byType(ImportRunSheetBody), findsOneWidget);
    verify(() => cubit.confirm(saveTemplateAs: null)).called(1);
  });

  testWidgets('closes itself when a cancelled commit rolls back to the preview step',
      (tester) async {
    final controller = StreamController<ImportFlowState>.broadcast();
    addTearDown(controller.close);
    var state = const ImportFlowState(
      step: ImportFlowStep.preview,
      runStatus: ImportFlowRunStatus.committing,
    );
    when(() => cubit.state).thenAnswer((_) => state);
    whenListen(cubit, controller.stream, initialState: state);

    await pumpTrigger(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(find.byType(ImportRunSheetBody), findsOneWidget);

    state = const ImportFlowState(
      step: ImportFlowStep.preview,
    );
    controller.add(state);
    await tester.pumpAndSettle();

    expect(find.byType(ImportRunSheetBody), findsNothing);
  });
}
