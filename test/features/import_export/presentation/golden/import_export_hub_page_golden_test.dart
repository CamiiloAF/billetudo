import 'package:billetudo/features/import_export/domain/entities/import_batch.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_export_hub_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_export_hub_state.dart';
import 'package:billetudo/features/import_export/presentation/pages/import_export_hub_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockImportExportHubCubit extends MockCubit<ImportExportHubState>
    implements ImportExportHubCubit {}

void main() {
  late MockImportExportHubCubit cubit;

  final batch = ImportBatch(
    id: 'batch-1',
    fileName: 'movimientos-banco.csv',
    importedAt: DateTime(2026, 7, 20),
    rowsImported: 128,
    rowsSkipped: 3,
    createdAt: DateTime(2026, 7, 20),
    updatedAt: 0,
  );

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockImportExportHubCubit());

  Future<void> golden(
    WidgetTester tester,
    ImportExportHubState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    // `ImportExportHubContent._relativeTime` reads `clock.now()` for the
    // "hace X días" caption under the last backup / latest batch rows —
    // pinning the clock keeps it from drifting a day at a time as this
    // golden ages, same fix as `transaction_form_page_golden_test.dart`.
    await pumpWithFixedClock(
      tester,
      BlocProvider<ImportExportHubCubit>.value(
        value: cubit,
        child: ImportExportHubPage(
          onSaveCopy: () {},
          onExportCsv: () {},
          onImportCsv: () {},
          onRestore: () {},
          onSeeImportHistory: () {},
          onOpenBatch: (_) {},
        ),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1100),
    );
    await expectLater(
      find.byType(ImportExportHubPage),
      matchesGoldenFile('goldens/import_export_hub_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('with data ($suffix)', (tester) async {
      await golden(
        tester,
        ImportExportHubState(
          status: ImportExportHubStatus.ready,
          lastBackupSavedAt: DateTime(2026, 7, 25),
          latestBatch: batch,
        ),
        'with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('no previous copy ($suffix)', (tester) async {
      await golden(
        tester,
        const ImportExportHubState(status: ImportExportHubStatus.ready),
        'no_copy_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('empty, brand new user ($suffix)', (tester) async {
      await golden(
        tester,
        const ImportExportHubState(
          status: ImportExportHubStatus.ready,
          hasAnyTransactions: false,
        ),
        'empty_$suffix',
        brightness: brightness,
      );
    });
  }
}
