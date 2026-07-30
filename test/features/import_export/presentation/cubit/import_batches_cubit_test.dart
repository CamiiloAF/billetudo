import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/import_export/domain/entities/import_batch.dart';
import 'package:billetudo/features/import_export/domain/entities/undo_summary.dart';
import 'package:billetudo/features/import_export/domain/usecases/undo_import_batch.dart';
import 'package:billetudo/features/import_export/domain/usecases/watch_import_batches.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_batches_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_batches_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchImportBatches extends Mock implements WatchImportBatches {}

class MockUndoImportBatch extends Mock implements UndoImportBatch {}

void main() {
  late MockWatchImportBatches watchImportBatches;
  late MockUndoImportBatch undoImportBatch;

  final batch = ImportBatch(
    id: 'batch-1',
    fileName: 'movimientos.csv',
    importedAt: DateTime(2026, 7, 1),
    rowsImported: 10,
    rowsSkipped: 2,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: 0,
  );

  const summary = UndoSummary(
    transactionsTrashed: 10,
    accountsTrashed: 0,
    accountsKept: 0,
    categoriesTrashed: 0,
    categoriesKept: 0,
    tagsTrashed: 0,
    tagsKept: 0,
    manuallyEditedRowsTrashed: 0,
  );

  setUp(() {
    watchImportBatches = MockWatchImportBatches();
    undoImportBatch = MockUndoImportBatch();
    when(watchImportBatches.call).thenAnswer((_) => Stream.value(Right([batch])));
  });

  ImportBatchesCubit build() => ImportBatchesCubit(watchImportBatches, undoImportBatch);

  blocTest<ImportBatchesCubit, ImportBatchesState>(
    'start emite loading y luego la lista (HU-08 historial, nunca oculta lotes revertidos)',
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [
      isA<ImportBatchesState>()
          .having((s) => s.status, 'status', ImportBatchesStatus.loading),
      isA<ImportBatchesState>()
          .having((s) => s.status, 'status', ImportBatchesStatus.ready)
          .having((s) => s.batches, 'batches', [batch]),
    ],
  );

  blocTest<ImportBatchesCubit, ImportBatchesState>(
    'undo exitoso guarda el resumen de la reversión',
    build: build,
    setUp: () => when(() => undoImportBatch('batch-1'))
        .thenAnswer((_) async => const Right(summary)),
    act: (cubit) => cubit.undo('batch-1'),
    expect: () => [
      isA<ImportBatchesState>()
          .having((s) => s.lastUndoSummary, 'lastUndoSummary', summary),
    ],
  );

  blocTest<ImportBatchesCubit, ImportBatchesState>(
    'undo fallido deja un failure sin resumen',
    build: build,
    setUp: () => when(() => undoImportBatch('batch-1')).thenAnswer(
      (_) async => const Left(DatabaseFailure('boom')),
    ),
    act: (cubit) => cubit.undo('batch-1'),
    expect: () => [
      isA<ImportBatchesState>().having(
        (s) => s.failure,
        'failure',
        isA<DatabaseFailure>(),
      ),
    ],
  );
}
