import 'package:billetudo/core/error/failure.dart';
import 'package:billetudo/features/import_export/domain/entities/export_scope.dart';
import 'package:billetudo/features/import_export/presentation/cubit/export_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/export_state.dart';
import 'package:billetudo/features/import_export/presentation/pages/export_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockExportCubit extends MockCubit<ExportState> implements ExportCubit {}

void main() {
  late MockExportCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockExportCubit());

  Future<void> golden(
    WidgetTester tester,
    ExportState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<ExportCubit>.value(value: cubit, child: const ExportPage()),
      brightness: brightness,
      settle: settle,
    );
    await expectLater(
      find.byType(ExportPage),
      matchesGoldenFile('goldens/export_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('select and filter, defaults ($suffix)', (tester) async {
      await golden(tester, const ExportState(), 'select_filter_$suffix', brightness: brightness);
    });

    testWidgets('filters dimmed, transactions toggle off ($suffix)', (tester) async {
      await golden(
        tester,
        const ExportState(
          scope: ExportScope(includeTransactions: false, includeAccounts: true),
        ),
        'filters_dimmed_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('empty, no transactions to export ($suffix)', (tester) async {
      await golden(
        tester,
        const ExportState(
          scope: ExportScope(includeTransactions: false),
          hasAnyTransactions: false,
        ),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('running, progress ($suffix)', (tester) async {
      await golden(
        tester,
        const ExportState(
          runStatus: ExportRunStatus.running,
          processed: 420,
          total: 1200,
        ),
        'progress_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('write failure ($suffix)', (tester) async {
      await golden(
        tester,
        const ExportState(runStatus: ExportRunStatus.error, failure: IoFailure('boom')),
        'error_$suffix',
        brightness: brightness,
      );
    });
  }
}
