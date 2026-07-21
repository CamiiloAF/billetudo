import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/advance_scheduled_occurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
import 'scheduled_payment_repository_mock.dart';

/// HU-05 "Confirmar ahora" (`docs/bugfixes.md` point 1).
void main() {
  late MockScheduledPaymentRepository repository;
  late AdvanceScheduledOccurrence advance;

  setUp(() {
    repository = MockScheduledPaymentRepository();
    advance = AdvanceScheduledOccurrence(repository);
  });

  test('camino feliz: delega en el repositorio y retorna lo que este emita',
      () async {
    final pending = buildPendingOccurrence();
    when(() => repository.advanceScheduledOccurrence('sp-1'))
        .thenAnswer((_) async => Right(pending));

    final result = await advance(scheduledPaymentId: 'sp-1');

    expect(result.getRight().toNullable(), pending);
    verify(() => repository.advanceScheduledOccurrence('sp-1')).called(1);
  });

  test('un id vacío se rechaza sin llamar al repositorio', () async {
    final result = await advance(scheduledPaymentId: '   ');

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.advanceScheduledOccurrence(any()));
  });

  test('reenvía la falla del repositorio (nada que confirmar, endDate, etc.)',
      () async {
    when(() => repository.advanceScheduledOccurrence('sp-1')).thenAnswer(
      (_) async => const Left(
        ValidationFailure('this scheduled payment has nothing left to confirm'),
      ),
    );

    final result = await advance(scheduledPaymentId: 'sp-1');

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });
}
