import 'package:billetudo/features/import_export/domain/entities/backup_header.dart';
import 'package:billetudo/features/import_export/domain/entities/restore_mode.dart';
import 'package:billetudo/features/import_export/domain/entities/restore_summary.dart';
import 'package:billetudo/features/import_export/presentation/cubit/restore_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/restore_state.dart';
import 'package:billetudo/features/import_export/presentation/pages/restore_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockRestoreCubit extends MockCubit<RestoreState> implements RestoreCubit {}

void main() {
  late MockRestoreCubit cubit;

  final header = BackupHeader(
    formatVersion: 1,
    schemaVersion: 9,
    appVersion: '1.4.0',
    createdAt: DateTime(2026, 7, 15),
    rowCountsByTable: const {'transactions': 512, 'accounts': 4, 'categories': 20},
  );

  final doneSummary = const RestoreSummary(
    mode: RestoreMode.merge,
    createdByTable: {'transactions': 480, 'accounts': 1},
    updatedByTable: {'transactions': 30},
    skippedByTable: {'transactions': 2},
  );

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockRestoreCubit());

  Future<void> golden(
    WidgetTester tester,
    RestoreState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<RestoreCubit>.value(
        value: cubit,
        child: RestorePage(onDone: () {}),
      ),
      brightness: brightness,
      settle: settle,
    );
    await expectLater(
      find.byType(RestorePage),
      matchesGoldenFile('goldens/restore_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('pick file entry ($suffix)', (tester) async {
      await golden(tester, const RestoreState(), 'pick_file_$suffix', brightness: brightness);
    });

    testWidgets('summary, merge chosen ($suffix)', (tester) async {
      await golden(
        tester,
        RestoreState(step: RestoreStep.summary, header: header),
        'summary_merge_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('summary, replace all selected ($suffix)', (tester) async {
      await golden(
        tester,
        RestoreState(
          step: RestoreStep.summary,
          header: header,
          mode: RestoreMode.replaceAll,
        ),
        'summary_replace_selected_$suffix',
        brightness: brightness,
      );
    });

    // `NY5o6`/`MjNwC`: the escalated "Reemplazar todo" confirmation is its
    // own step, separate from the mode-choice summary above.
    testWidgets('replace all confirm, inert (unacknowledged) ($suffix)', (tester) async {
      await golden(
        tester,
        RestoreState(
          step: RestoreStep.replaceAllConfirm,
          header: header,
          mode: RestoreMode.replaceAll,
        ),
        'replace_all_confirm_inert_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('replace all confirm, acknowledged ($suffix)', (tester) async {
      await golden(
        tester,
        RestoreState(
          step: RestoreStep.replaceAllConfirm,
          header: header,
          mode: RestoreMode.replaceAll,
          replaceAllAcknowledged: true,
        ),
        'replace_all_confirm_acknowledged_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('running, progress ($suffix)', (tester) async {
      await golden(
        tester,
        const RestoreState(step: RestoreStep.running, processed: 3, total: 8),
        'progress_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('done ($suffix)', (tester) async {
      await golden(
        tester,
        RestoreState(step: RestoreStep.done, summary: doneSummary),
        'done_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error, newer format version rejected ($suffix)', (tester) async {
      await golden(
        tester,
        const RestoreState(step: RestoreStep.error),
        'error_$suffix',
        brightness: brightness,
      );
    });
  }
}
