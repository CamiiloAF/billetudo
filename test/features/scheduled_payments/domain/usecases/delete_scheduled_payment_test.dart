import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/delete_scheduled_payment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'scheduled_payment_repository_mock.dart';

void main() {
  late MockScheduledPaymentRepository repository;

  setUp(() {
    repository = MockScheduledPaymentRepository();
  });

  test('HU-05: delega el borrado (tombstonedAt) al repositorio', () async {
    when(() => repository.deleteScheduledPayment('sp-1'))
        .thenAnswer((_) async => const Right(unit));
    final deleteScheduledPayment = DeleteScheduledPayment(repository);

    final result = await deleteScheduledPayment('sp-1');

    expect(result.isRight(), isTrue);
    verify(() => repository.deleteScheduledPayment('sp-1')).called(1);
  });

  test('propaga el fallo del repositorio', () async {
    when(() => repository.deleteScheduledPayment('sp-1')).thenAnswer(
      (_) async => const Left(NotFoundFailure('no existe')),
    );
    final deleteScheduledPayment = DeleteScheduledPayment(repository);

    final result = await deleteScheduledPayment('sp-1');

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });
}
