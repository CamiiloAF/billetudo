import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/import_export/domain/entities/backup_header.dart';
import 'package:billetudo/features/import_export/domain/entities/restore_mode.dart';
import 'package:billetudo/features/import_export/domain/entities/restore_summary.dart';
import 'package:billetudo/features/import_export/domain/usecases/parse_backup_header.dart';
import 'package:billetudo/features/import_export/domain/usecases/restore_backup.dart';
import 'package:billetudo/features/import_export/presentation/cubit/restore_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/restore_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockParseBackupHeader extends Mock implements ParseBackupHeader {}

class MockRestoreBackup extends Mock implements RestoreBackup {}

void main() {
  late MockParseBackupHeader parseBackupHeader;
  late MockRestoreBackup restoreBackup;

  final header = BackupHeader(
    formatVersion: 1,
    schemaVersion: 9,
    appVersion: '0.0.3',
    createdAt: DateTime(2026, 1, 1),
    rowCountsByTable: const {},
  );

  setUpAll(() {
    registerFallbackValue(RestoreMode.merge);
  });

  setUp(() {
    parseBackupHeader = MockParseBackupHeader();
    restoreBackup = MockRestoreBackup();
  });

  RestoreCubit build() => RestoreCubit(parseBackupHeader, restoreBackup);

  group('canConfirm (HU-04 escalated confirmation)', () {
    blocTest<RestoreCubit, RestoreState>(
      'merge mode never needs the acknowledgement checkbox',
      build: build,
      act: (cubit) => cubit.setMode(RestoreMode.merge),
      verify: (cubit) => expect(cubit.state.canConfirm, isTrue),
    );

    blocTest<RestoreCubit, RestoreState>(
      'replaceAll blocks confirm until acknowledged is checked',
      build: build,
      act: (cubit) => cubit.setMode(RestoreMode.replaceAll),
      verify: (cubit) => expect(cubit.state.canConfirm, isFalse),
    );

    blocTest<RestoreCubit, RestoreState>(
      'replaceAll + acknowledged unlocks confirm',
      build: build,
      act: (cubit) {
        cubit.setMode(RestoreMode.replaceAll);
        cubit.setReplaceAllAcknowledged(value: true);
      },
      verify: (cubit) => expect(cubit.state.canConfirm, isTrue),
    );

    blocTest<RestoreCubit, RestoreState>(
      'switching mode resets the acknowledgement',
      build: build,
      act: (cubit) {
        cubit.setMode(RestoreMode.replaceAll);
        cubit.setReplaceAllAcknowledged(value: true);
        cubit.setMode(RestoreMode.merge);
        cubit.setMode(RestoreMode.replaceAll);
      },
      verify: (cubit) => expect(cubit.state.replaceAllAcknowledged, isFalse),
    );
  });

  test('dismissError vuelve al paso de seleccionar archivo', () async {
    final cubit = build();
    addTearDown(cubit.close);
    cubit.dismissError();
    expect(cubit.state.step, RestoreStep.pickFile);
  });

  group('confirm — HU-04/HU-09', () {
    const summary = RestoreSummary(
      mode: RestoreMode.merge,
      createdByTable: {},
      updatedByTable: {},
      skippedByTable: {},
    );

    blocTest<RestoreCubit, RestoreState>(
      'reporta progreso real (tablas fusionadas / total)',
      setUp: () {
        when(() => parseBackupHeader(any())).thenAnswer((_) async => Right(header));
        when(
          () => restoreBackup(
            inputPath: any(named: 'inputPath'),
            mode: any(named: 'mode'),
            onProgress: any(named: 'onProgress'),
            cancellationToken: any(named: 'cancellationToken'),
          ),
        ).thenAnswer((invocation) async {
          final onProgress =
              invocation.namedArguments[#onProgress] as void Function(int, int?)?;
          onProgress?.call(0, 19);
          onProgress?.call(19, 19);
          return const Right(summary);
        });
      },
      build: build,
      seed: () => const RestoreState(step: RestoreStep.summary, filePath: 'copia.json'),
      act: (cubit) => cubit.confirm(),
      verify: (cubit) {
        expect(cubit.state.processed, 19);
        expect(cubit.state.total, 19);
        expect(cubit.state.step, RestoreStep.done);
      },
    );

    blocTest<RestoreCubit, RestoreState>(
      'cancel vuelve al resumen (no a un error) — el rollback no dejó nada a medias',
      setUp: () {
        when(() => parseBackupHeader(any())).thenAnswer((_) async => Right(header));
        when(
          () => restoreBackup(
            inputPath: any(named: 'inputPath'),
            mode: any(named: 'mode'),
            onProgress: any(named: 'onProgress'),
            cancellationToken: any(named: 'cancellationToken'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            IoFailure('restore cancelled', reason: IoFailureReason.cancelled),
          ),
        );
      },
      build: build,
      seed: () => const RestoreState(step: RestoreStep.summary, filePath: 'copia.json'),
      act: (cubit) => cubit.confirm(),
      verify: (cubit) {
        expect(cubit.state.step, RestoreStep.summary);
        expect(cubit.state.failure, isNull);
      },
    );
  });
}
