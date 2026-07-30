import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/import_export/domain/entities/import_batch.dart';
import 'package:billetudo/features/import_export/domain/usecases/get_last_backup_saved_at.dart';
import 'package:billetudo/features/import_export/domain/usecases/watch_import_batches.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_export_hub_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_export_hub_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetLastBackupSavedAt extends Mock implements GetLastBackupSavedAt {}

class MockWatchImportBatches extends Mock implements WatchImportBatches {}

void main() {
  late MockGetLastBackupSavedAt getLastBackupSavedAt;
  late MockWatchImportBatches watchImportBatches;

  final batch = ImportBatch(
    id: 'batch-1',
    fileName: 'movimientos.csv',
    importedAt: DateTime(2026, 7, 1),
    rowsImported: 10,
    rowsSkipped: 0,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: 0,
  );

  setUp(() {
    getLastBackupSavedAt = MockGetLastBackupSavedAt();
    watchImportBatches = MockWatchImportBatches();
    when(watchImportBatches.call).thenAnswer((_) => Stream.value(Right([batch])));
  });

  ImportExportHubCubit build() =>
      ImportExportHubCubit(getLastBackupSavedAt, watchImportBatches);

  blocTest<ImportExportHubCubit, ImportExportHubState>(
    'start sin copia previa deja lastBackupSavedAt nulo (contenido, no error)',
    build: () {
      when(getLastBackupSavedAt.call).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (cubit) => cubit.start(),
    expect: () => [
      isA<ImportExportHubState>().having(
        (s) => s.status,
        'status',
        ImportExportHubStatus.loading,
      ),
      isA<ImportExportHubState>()
          .having((s) => s.status, 'status', ImportExportHubStatus.ready)
          .having((s) => s.hasCopy, 'hasCopy', isFalse),
      isA<ImportExportHubState>().having((s) => s.latestBatch, 'latestBatch', batch),
    ],
  );

  blocTest<ImportExportHubCubit, ImportExportHubState>(
    'start con copia previa refleja la fecha guardada',
    build: () {
      when(getLastBackupSavedAt.call)
          .thenAnswer((_) async => Right(DateTime(2026, 7, 12)));
      return build();
    },
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<ImportExportHubState>()
          .having((s) => s.hasCopy, 'hasCopy', isTrue)
          .having((s) => s.lastBackupSavedAt, 'lastBackupSavedAt', DateTime(2026, 7, 12)),
      isA<ImportExportHubState>(),
    ],
  );

  blocTest<ImportExportHubCubit, ImportExportHubState>(
    'markBackupJustSaved actualiza el hero sin esperar un refresh completo',
    build: () {
      when(getLastBackupSavedAt.call).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (cubit) async {
      await cubit.start();
      cubit.markBackupJustSaved(DateTime(2026, 7, 29));
    },
    skip: 3,
    expect: () => [
      isA<ImportExportHubState>()
          .having((s) => s.lastBackupSavedAt, 'lastBackupSavedAt', DateTime(2026, 7, 29)),
    ],
  );
}
