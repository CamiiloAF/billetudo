import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/zero_based_summary.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_zero_based_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'budget_repository_mock.dart';

void main() {
  late MockBudgetRepository repository;
  late GetZeroBasedSummary getZeroBasedSummary;

  setUp(() {
    repository = MockBudgetRepository();
    getZeroBasedSummary = GetZeroBasedSummary(repository);
  });

  test('HU-06: forwards the repository stream unchanged', () {
    const summary = ZeroBasedSummary(
      currency: 'COP',
      incomeMinor: 500000,
      assignedMinor: 300000,
    );
    when(() => repository.watchZeroBasedSummary())
        .thenAnswer((_) => Stream.value(const Right(summary)));

    final stream = getZeroBasedSummary();

    expect(stream, emits(const Right<Object, ZeroBasedSummary?>(summary)));
  });

  test('a null payload (nothing to show) passes through as-is', () {
    when(() => repository.watchZeroBasedSummary())
        .thenAnswer((_) => Stream.value(const Right(null)));

    final stream = getZeroBasedSummary();

    expect(stream, emits(const Right<Object, ZeroBasedSummary?>(null)));
  });

  test('propagates a repository failure', () {
    when(() => repository.watchZeroBasedSummary()).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    );

    final stream = getZeroBasedSummary();

    expect(
      stream,
      emits(isA<Left<Failure, ZeroBasedSummary?>>()),
    );
  });
}
