import 'package:billetudo/core/error/failure.dart';
import 'package:billetudo/features/import_export/domain/entities/import_batch.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_batches_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_batches_state.dart';
import 'package:billetudo/features/import_export/presentation/pages/import_batches_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockImportBatchesCubit extends MockCubit<ImportBatchesState>
    implements ImportBatchesCubit {}

void main() {
  late MockImportBatchesCubit cubit;

  final activeBatch = ImportBatch(
    id: 'batch-1',
    fileName: 'movimientos-banco.csv',
    importedAt: DateTime(2026, 7, 20),
    rowsImported: 128,
    rowsSkipped: 3,
    createdAt: DateTime(2026, 7, 20),
    updatedAt: 0,
  );

  final revertedBatch = ImportBatch(
    id: 'batch-2',
    fileName: 'wallet-export-abril.csv',
    importedAt: DateTime(2026, 4, 3),
    rowsImported: 56,
    rowsSkipped: 0,
    createdAt: DateTime(2026, 4, 3),
    updatedAt: 0,
    revertedAt: DateTime(2026, 4, 10),
  );

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockImportBatchesCubit());

  Future<void> golden(
    WidgetTester tester,
    ImportBatchesState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<ImportBatchesCubit>.value(
        value: cubit,
        child: const ImportBatchesPage(),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(ImportBatchesPage),
      matchesGoldenFile('goldens/import_batches_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('history with batches ($suffix)', (tester) async {
      await golden(
        tester,
        ImportBatchesState(
          status: ImportBatchesStatus.ready,
          batches: [activeBatch, revertedBatch],
        ),
        'with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('history empty ($suffix)', (tester) async {
      await golden(
        tester,
        const ImportBatchesState(status: ImportBatchesStatus.ready),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('history failure ($suffix)', (tester) async {
      await golden(
        tester,
        const ImportBatchesState(
          status: ImportBatchesStatus.failure,
          failure: DatabaseFailure('boom'),
        ),
        'failure_$suffix',
        brightness: brightness,
      );
    });
  }
}
