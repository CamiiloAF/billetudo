import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/domain/usecases/get_pending_upload_count.dart';
import 'package:billetudo/features/auth/presentation/cubit/sign_out_sheet_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/sign_out_sheet_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetPendingUploadCount extends Mock implements GetPendingUploadCount {}

void main() {
  late MockGetPendingUploadCount getPendingUploadCount;

  setUp(() {
    getPendingUploadCount = MockGetPendingUploadCount();
  });

  void whenCount(Result<int> result) =>
      when(() => getPendingUploadCount()).thenAnswer((_) async => result);

  SignOutSheetCubit build() => SignOutSheetCubit(getPendingUploadCount);

  group('estado inicial', () {
    test('arranca conservando los datos y sin conteo (HU-06)', () {
      whenCount(const Right(0));

      final cubit = build();
      addTearDown(cubit.close);

      expect(cubit.state.deleteLocalData, isFalse);
      expect(cubit.state.pendingUploadCount, 0);
      expect(cubit.state.showsUnsyncedWarning, isFalse);
    });
  });

  group('start', () {
    blocTest<SignOutSheetCubit, SignOutSheetState>(
      'con Right(4) emite el conteo leído de la cola',
      setUp: () => whenCount(const Right(4)),
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => const <SignOutSheetState>[
        SignOutSheetState(pendingUploadCount: 4),
      ],
      verify: (cubit) {
        verify(() => getPendingUploadCount()).called(1);
        // El opt-in no se toca al leer la cola: leer no decide por el usuario.
        expect(cubit.state.deleteLocalData, isFalse);
      },
    );

    blocTest<SignOutSheetCubit, SignOutSheetState>(
      'con Left no emite nada y el conteo queda en 0 (leer la cola nunca '
      'bloquea la hoja — decisión #17)',
      setUp: () => whenCount(
        const Left<Failure, int>(DatabaseFailure('cola ilegible')),
      ),
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => const <SignOutSheetState>[],
      verify: (cubit) {
        expect(cubit.state.pendingUploadCount, 0);
        expect(cubit.state.showsUnsyncedWarning, isFalse);
      },
    );

    test('un start() que resuelve después de close() no explota', () async {
      final completer = Completer<Result<int>>();
      when(() => getPendingUploadCount())
          .thenAnswer((_) => completer.future);

      final cubit = build();
      final pending = cubit.start();

      await cubit.close();
      completer.complete(const Right(7));

      // Sin el guard `isClosed`, este await tiraría el
      // `StateError: Cannot emit new states after calling close`.
      await expectLater(pending, completes);
      expect(cubit.state.pendingUploadCount, 0);
    });
  });

  group('toggleDeleteLocalData', () {
    blocTest<SignOutSheetCubit, SignOutSheetState>(
      'alterna el opt-in en cada llamada, conservando el conteo',
      setUp: () => whenCount(const Right(3)),
      build: build,
      act: (cubit) async {
        await cubit.start();
        cubit
          ..toggleDeleteLocalData()
          ..toggleDeleteLocalData();
      },
      expect: () => const <SignOutSheetState>[
        SignOutSheetState(pendingUploadCount: 3),
        SignOutSheetState(deleteLocalData: true, pendingUploadCount: 3),
        SignOutSheetState(pendingUploadCount: 3),
      ],
    );
  });

  group('showsUnsyncedWarning', () {
    test('solo con el opt-in encendido y conteo > 0', () {
      const off = SignOutSheetState(pendingUploadCount: 4);
      const onWithQueue =
          SignOutSheetState(deleteLocalData: true, pendingUploadCount: 4);
      const onEmptyQueue = SignOutSheetState(deleteLocalData: true);

      expect(off.showsUnsyncedWarning, isFalse);
      expect(onWithQueue.showsUnsyncedWarning, isTrue);
      expect(onEmptyQueue.showsUnsyncedWarning, isFalse);
    });
  });
}
