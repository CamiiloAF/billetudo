import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/usecases/get_linkable_scheduled_payments.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_linkable_scheduled_payments.dart'
    as scheduled_payments;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../scheduled_payments/domain/usecases/scheduled_payment_repository_mock.dart';
import '../../../scheduled_payments/scheduled_payment_fixtures.dart';

void main() {
  late MockScheduledPaymentRepository repository;
  late GetLinkableScheduledPayments usecase;

  setUp(() {
    repository = MockScheduledPaymentRepository();
    usecase = GetLinkableScheduledPayments(
      scheduled_payments.GetLinkableScheduledPayments(repository),
    );
  });

  test('delegates to the scheduled_payments use case unchanged', () async {
    final summary = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(),
      accountName: 'Efectivo',
    );
    when(() => repository.watchLinkableScheduledPayments())
        .thenAnswer((_) => Stream.value(Right([summary])));

    final result = await usecase().first;

    expect(result.getRight().toNullable(), [summary]);
  });
}
