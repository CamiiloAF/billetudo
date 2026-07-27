import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/create_scheduled_payment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
import 'scheduled_payment_repository_mock.dart';

void main() {
  late MockScheduledPaymentRepository repository;
  late CreateScheduledPayment createScheduledPayment;

  setUpAll(registerScheduledPaymentFallbacks);

  setUp(() {
    repository = MockScheduledPaymentRepository();
    createScheduledPayment = CreateScheduledPayment(repository);
    when(() => repository.createScheduledPayment(any())).thenAnswer(
      (invocation) async => Right(
        buildScheduledPayment(
          accountId:
              (invocation.positionalArguments.first as ScheduledPaymentDraft)
                  .accountId,
        ),
      ),
    );
  });

  ScheduledPaymentDraft capturedDraft() =>
      verify(() => repository.createScheduledPayment(captureAny()))
          .captured
          .single as ScheduledPaymentDraft;

  test('HU-01: persiste una plantilla válida', () async {
    final result = await createScheduledPayment(buildExpenseDraft());

    expect(result.isRight(), isTrue);
    expect(capturedDraft().type, ScheduledPaymentType.expense);
  });

  test('HU-01: rechaza sin cuenta antes de llegar al repositorio', () async {
    final result =
        await createScheduledPayment(buildExpenseDraft(accountId: ''));

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.createScheduledPayment(any()));
  });

  test('criterio 16: rechaza transferencia con cuentas iguales', () async {
    final result = await createScheduledPayment(
      buildTransferDraft(transferAccountId: 'acc-1'),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.createScheduledPayment(any()));
  });

  test('propaga el fallo del repositorio sin envolverlo', () async {
    when(() => repository.createScheduledPayment(any())).thenAnswer(
      (_) async => const Left(DatabaseFailure('disco lleno')),
    );

    final result = await createScheduledPayment(buildExpenseDraft());

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
