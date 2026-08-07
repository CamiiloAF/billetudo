import 'dart:io';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/import_export/domain/entities/backup_header.dart';
import 'package:billetudo/features/import_export/domain/usecases/create_full_backup.dart';
import 'package:billetudo/features/import_export/domain/usecases/mark_backup_saved.dart';
import 'package:billetudo/features/import_export/presentation/cubit/save_copy_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/save_copy_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'fake_path_provider.dart';

class MockCreateFullBackup extends Mock implements CreateFullBackup {}

class MockMarkBackupSaved extends Mock implements MarkBackupSaved {}

void main() {
  late MockCreateFullBackup createFullBackup;
  late MockMarkBackupSaved markBackupSaved;
  late Directory tempDir;

  final header = BackupHeader(
    formatVersion: 1,
    schemaVersion: 9,
    appVersion: '0.0.3',
    createdAt: DateTime(2026, 1, 1),
    rowCountsByTable: const {},
  );

  setUp(() {
    createFullBackup = MockCreateFullBackup();
    markBackupSaved = MockMarkBackupSaved();
    tempDir = Directory.systemTemp.createTempSync('billetudo_save_copy_cubit_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    when(() => markBackupSaved(any())).thenAnswer((_) async => const Right(unit));
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  SaveCopyCubit build() => SaveCopyCubit(createFullBackup, markBackupSaved);

  blocTest<SaveCopyCubit, SaveCopyState>(
    'start reporta progreso creciente hasta terminar (HU-03/HU-09)',
    setUp: () {
      when(
        () => createFullBackup(
          outputPath: any(named: 'outputPath'),
          onProgress: any(named: 'onProgress'),
          cancellationToken: any(named: 'cancellationToken'),
        ),
      ).thenAnswer((invocation) async {
        final onProgress =
            invocation.namedArguments[#onProgress] as void Function(int, int?)?;
        onProgress?.call(0, 19);
        onProgress?.call(10, 19);
        onProgress?.call(19, 19);
        return Right(header);
      });
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.processed, 19);
      expect(cubit.state.total, 19);
      expect(cubit.state.status, SaveCopyStatus.done);
      expect(cubit.state.savedAt, header.createdAt);
    },
  );

  blocTest<SaveCopyCubit, SaveCopyState>(
    'cancel deja el estado "cancelled", no "error" (HU-03/HU-09)',
    setUp: () {
      when(
        () => createFullBackup(
          outputPath: any(named: 'outputPath'),
          onProgress: any(named: 'onProgress'),
          cancellationToken: any(named: 'cancellationToken'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          IoFailure('backup cancelled', reason: IoFailureReason.cancelled),
        ),
      );
    },
    build: build,
    act: (cubit) async => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.status, SaveCopyStatus.cancelled);
      expect(cubit.state.failure, isNull);
      verifyNever(() => markBackupSaved(any()));
    },
  );
}
