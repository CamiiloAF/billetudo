import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/import_export/domain/entities/undo_summary.dart';
import 'package:billetudo/features/import_export/domain/repositories/import_batch_repository.dart';
import 'package:billetudo/features/import_export/domain/usecases/undo_import_batch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockImportBatchRepository extends Mock implements ImportBatchRepository {}

void main() {
  late MockImportBatchRepository repository;
  late UndoImportBatch undoImportBatch;

  setUp(() {
    repository = MockImportBatchRepository();
    undoImportBatch = UndoImportBatch(repository);
  });

  test('delega la reversión al repositorio y devuelve su resumen', () async {
    const summary = UndoSummary(
      transactionsTrashed: 3,
      accountsTrashed: 1,
      accountsKept: 1,
      categoriesTrashed: 0,
      categoriesKept: 2,
      tagsTrashed: 0,
      tagsKept: 0,
      manuallyEditedRowsTrashed: 1,
    );
    when(() => repository.undoBatch('batch-1'))
        .thenAnswer((_) async => const Right(summary));

    final result = await undoImportBatch('batch-1');

    expect(result.getRight().toNullable(), summary);
    verify(() => repository.undoBatch('batch-1')).called(1);
  });

  test('propaga el fallo del repositorio sin envolverlo', () async {
    when(() => repository.undoBatch('batch-1')).thenAnswer(
      (_) async => const Left(NotFoundFailure('no existe')),
    );

    final result = await undoImportBatch('batch-1');

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });
}
