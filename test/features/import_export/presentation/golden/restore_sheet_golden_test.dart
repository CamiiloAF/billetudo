import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/import_export/domain/entities/backup_header.dart';
import 'package:billetudo/features/import_export/domain/entities/restore_mode.dart';
import 'package:billetudo/features/import_export/domain/entities/restore_summary.dart';
import 'package:billetudo/features/import_export/presentation/cubit/restore_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/restore_state.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/restore_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockRestoreCubit extends MockCubit<RestoreState> implements RestoreCubit {}

/// HU-04's restore flow, now a modal sheet (`RestoreSheetBody`, decision
/// 2026-08-06) instead of a full page (`restore_page.dart`, removed). Covers
/// every step the sheet renders itself — `RestoreStep.pickFile` is excluded
/// on purpose: `RestoreSheet.show` never opens the sheet on that step (it
/// only shows up defensively, rendering `SizedBox.shrink()`), same reasoning
/// `import_flow_page_test.dart` used to drop its own "select file entry"
/// golden in favor of a behavior test.
///
/// Rendered by wiring `RestoreSheetBody` directly to a mocked cubit inside a
/// real `showModalBottomSheet` (scrim, drag handle and the `[28,28,0,0]`
/// bottom sheet theme included) instead of going through
/// `RestoreSheet.show`/`getIt`: the sheet's own `BlocProvider` resolves its
/// cubit from the DI container and the native file picker, neither of which
/// a golden test has any reason to stand up (same pattern
/// `confirmation_sheet_golden_test.dart` follows).
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
    Size size = goldenPhoneSize,
  }) async {
    when(() => cubit.state).thenReturn(state);
    setGoldenViewport(tester, size);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) => BlocProvider<RestoreCubit>.value(
                value: cubit,
                child: const BottomSheetBase(child: RestoreSheetBody()),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_restore_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

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
