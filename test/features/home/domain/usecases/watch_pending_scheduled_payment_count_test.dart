import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/home/domain/usecases/watch_pending_scheduled_payment_count.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../scheduled_payments/domain/usecases/scheduled_payment_repository_mock.dart';
import '../../../scheduled_payments/scheduled_payment_fixtures.dart';

/// `QuickAccessRow`'s "Pagos programados" badge (`njGBt`): the true pending
/// count, same due-date rule as `GetPendingOccurrences` so the badge and the
/// list it points to never disagree — "9+"/hide-on-zero live in the widget.
void main() {
  late MockScheduledPaymentRepository repository;
  late WatchPendingScheduledPaymentCount useCase;

  setUp(() {
    repository = MockScheduledPaymentRepository();
    useCase = WatchPendingScheduledPaymentCount(repository);
  });

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));

  test('cuenta 0 cuando no hay ocurrencias vencidas', () async {
    when(() => repository.watchPendingOccurrences()).thenAnswer(
      (_) => Stream.value(
        Right([
          buildPendingOccurrence(
            occurrence: buildOccurrence(id: 'occ-1', occurrenceDate: tomorrow),
          ),
        ]),
      ),
    );

    final result = await useCase().first;

    expect(result.getRight().toNullable(), 0);
  });

  test('cuenta solo las ocurrencias vencidas (hoy o antes)', () async {
    when(() => repository.watchPendingOccurrences()).thenAnswer(
      (_) => Stream.value(
        Right([
          buildPendingOccurrence(
            occurrence:
                buildOccurrence(id: 'occ-past', occurrenceDate: yesterday),
          ),
          buildPendingOccurrence(
            occurrence: buildOccurrence(id: 'occ-today', occurrenceDate: today),
          ),
          buildPendingOccurrence(
            occurrence:
                buildOccurrence(id: 'occ-future', occurrenceDate: tomorrow),
          ),
        ]),
      ),
    );

    final result = await useCase().first;

    expect(result.getRight().toNullable(), 2);
  });

  test('propaga un fallo del repositorio como Left', () async {
    const failure = DatabaseFailure('boom');
    when(() => repository.watchPendingOccurrences()).thenAnswer(
      (_) => Stream.value(const Left(failure)),
    );

    final result = await useCase().first;

    expect(result.getLeft().toNullable(), failure);
  });
}
