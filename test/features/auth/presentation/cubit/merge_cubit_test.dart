import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/merge_summary.dart';
import 'package:billetudo/features/auth/domain/usecases/merge_local_data.dart';
import 'package:billetudo/features/auth/presentation/cubit/merge_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/merge_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMergeLocalData extends Mock implements MergeLocalData {}

void main() {
  late MockMergeLocalData mergeLocalData;

  setUp(() {
    mergeLocalData = MockMergeLocalData();
  });

  const summary = MergeSummary(
    accountsCount: 3,
    transactionsCount: 20,
    categoriesCount: 8,
  );

  blocTest<MergeCubit, MergeState>(
    'HU-04: start reporta el resumen de la fusión',
    build: () => MergeCubit(mergeLocalData),
    setUp: () => when(() => mergeLocalData())
        .thenAnswer((_) async => const Right(summary)),
    act: (cubit) => cubit.start(),
    expect: () => [
      const MergeState(),
      const MergeState(status: MergeStatus.ready, summary: summary),
    ],
  );

  blocTest<MergeCubit, MergeState>(
    'un fallo del repositorio se refleja como failure',
    build: () => MergeCubit(mergeLocalData),
    setUp: () => when(() => mergeLocalData())
        .thenAnswer((_) async => const Left(NetworkFailure('offline'))),
    act: (cubit) => cubit.start(),
    expect: () => [
      const MergeState(),
      isA<MergeState>().having((s) => s.status, 'status', MergeStatus.failure),
    ],
  );

  blocTest<MergeCubit, MergeState>(
    'una excepción (backend no cableado) no crashea, emite failure',
    build: () => MergeCubit(mergeLocalData),
    setUp: () => when(() => mergeLocalData()).thenThrow(UnimplementedError()),
    act: (cubit) => cubit.start(),
    expect: () => [
      const MergeState(),
      isA<MergeState>().having((s) => s.status, 'status', MergeStatus.failure),
    ],
  );
}
