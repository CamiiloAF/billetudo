import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_pending_occurrences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
import 'scheduled_payment_repository_mock.dart';

void main() {
  late MockScheduledPaymentRepository repository;
  late GetPendingOccurrences getPendingOccurrences;

  setUp(() {
    repository = MockScheduledPaymentRepository();
    getPendingOccurrences = GetPendingOccurrences(repository);
  });

  // `call()` filters against the real clock (`isDueOn` uses `DateTime.now()`
  // internally, it is not injectable), so these fixtures anchor to it rather
  // than a fixed date to stay correct regardless of when the suite runs.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));

  PendingScheduledOccurrence pendingOn(DateTime date, {String id = 'occ-1'}) =>
      buildPendingOccurrence(
        occurrence: buildOccurrence(id: id, occurrenceDate: date),
      );

  test('una ocurrencia con fecha futura no aparece entre las pendientes',
      () async {
    when(() => repository.watchPendingOccurrences()).thenAnswer(
      (_) => Stream.value(Right([pendingOn(tomorrow)])),
    );

    final result = await getPendingOccurrences().first;

    expect(result.getRight().toNullable(), isEmpty);
  });

  test('una ocurrencia con fecha de hoy sí aparece entre las pendientes',
      () async {
    when(() => repository.watchPendingOccurrences()).thenAnswer(
      (_) => Stream.value(Right([pendingOn(today)])),
    );

    final result = await getPendingOccurrences().first;

    final items = result.getRight().toNullable()!;
    expect(items, hasLength(1));
    expect(items.single.occurrence.occurrenceDate, today);
  });

  test('una ocurrencia con fecha pasada sí aparece entre las pendientes',
      () async {
    when(() => repository.watchPendingOccurrences()).thenAnswer(
      (_) => Stream.value(Right([pendingOn(yesterday)])),
    );

    final result = await getPendingOccurrences().first;

    final items = result.getRight().toNullable()!;
    expect(items, hasLength(1));
    expect(items.single.occurrence.occurrenceDate, yesterday);
  });

  test('con 0 ocurrencias vencidas el resultado queda vacío, sin placeholders',
      () async {
    when(() => repository.watchPendingOccurrences()).thenAnswer(
      (_) => Stream.value(
        Right([
          pendingOn(tomorrow, id: 'occ-1'),
          pendingOn(tomorrow.add(const Duration(days: 5)), id: 'occ-2'),
        ]),
      ),
    );

    final result = await getPendingOccurrences().first;

    expect(result.getRight().toNullable(), isEmpty);
  });

  test('mezcla de fechas: solo pasan las vencidas, en el mismo orden recibido',
      () async {
    when(() => repository.watchPendingOccurrences()).thenAnswer(
      (_) => Stream.value(
        Right([
          pendingOn(yesterday, id: 'occ-past'),
          pendingOn(tomorrow, id: 'occ-future'),
          pendingOn(today, id: 'occ-today'),
        ]),
      ),
    );

    final result = await getPendingOccurrences().first;

    final ids = result.getRight().toNullable()!.map((i) => i.occurrence.id);
    expect(ids, ['occ-past', 'occ-today']);
  });
}
