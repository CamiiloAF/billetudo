import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import 'package:billetudo/features/scheduled_payments/domain/repositories/scheduled_payment_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockScheduledPaymentRepository extends Mock
    implements ScheduledPaymentRepository {}

/// Registers the fallbacks mocktail needs for `any()` on custom types.
void registerScheduledPaymentFallbacks() {
  registerFallbackValue(
    ScheduledPaymentDraft(
      accountId: 'fallback',
      amountMinor: 1,
      currency: 'COP',
      type: ScheduledPaymentType.expense,
      frequency: ScheduledPaymentFrequency.once,
      nextDate: DateTime(2026),
    ),
  );
}
