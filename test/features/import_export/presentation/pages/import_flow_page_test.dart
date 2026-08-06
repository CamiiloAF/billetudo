import 'package:billetudo/features/import_export/presentation/cubit/import_flow_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_flow_state.dart';
import 'package:billetudo/features/import_export/presentation/pages/import_flow_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockImportFlowCubit extends MockCubit<ImportFlowState> implements ImportFlowCubit {}

/// Covers the entry step's new behavior (`import_flow_page.dart`, decision
/// 2026-08-06): tapping "Importar desde un CSV" no longer renders an
/// intermediate sheet, it opens the OS file picker directly on mount. This
/// used to be a golden ("select file entry"), but the frame it captured is a
/// blank, transitory `Scaffold` — no pixel in it is meaningful to compare.
/// What actually matters here is behavior, so it belongs in a widget test.
void main() {
  late MockImportFlowCubit cubit;

  setUp(() {
    cubit = MockImportFlowCubit();
    when(() => cubit.state).thenReturn(const ImportFlowState());
  });

  Future<void> pumpPage(WidgetTester tester, {required VoidCallback onDone}) async {
    await tester.pumpWidget(
      wrapForGolden(
        BlocProvider<ImportFlowCubit>.value(
          value: cubit,
          child: ImportFlowPage(onDone: onDone),
        ),
        brightness: Brightness.light,
      ),
    );
  }

  testWidgets('calls pickFile() once as soon as it mounts on the entry step', (tester) async {
    when(() => cubit.pickFile()).thenAnswer((_) async {});

    await pumpPage(tester, onDone: () {});
    await tester.pump();

    verify(() => cubit.pickFile()).called(1);
  });

  testWidgets('does not call onDone when the picker hands off to the next step',
      (tester) async {
    when(() => cubit.pickFile()).thenAnswer((_) async {
      when(() => cubit.state)
          .thenReturn(const ImportFlowState(step: ImportFlowStep.mapping));
    });
    var doneCalled = false;

    await pumpPage(tester, onDone: () => doneCalled = true);
    await tester.pump();

    expect(doneCalled, isFalse);
  });

  testWidgets('calls onDone when the user backs out of the native picker without picking',
      (tester) async {
    when(() => cubit.pickFile()).thenAnswer((_) async {});
    var doneCalled = false;

    await pumpPage(tester, onDone: () => doneCalled = true);
    await tester.pump();

    expect(doneCalled, isTrue);
  });

  testWidgets('does not re-open the picker on unrelated rebuilds', (tester) async {
    when(() => cubit.pickFile()).thenAnswer((_) async {});

    await pumpPage(tester, onDone: () {});
    await tester.pump();
    // Rebuild with the same state (e.g. a parent widget rebuild) instead of
    // a real state transition.
    await tester.pumpWidget(
      wrapForGolden(
        BlocProvider<ImportFlowCubit>.value(
          value: cubit,
          child: ImportFlowPage(onDone: () {}),
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.pump();

    verify(() => cubit.pickFile()).called(1);
  });
}
