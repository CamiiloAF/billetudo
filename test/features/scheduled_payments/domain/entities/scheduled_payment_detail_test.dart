import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_detail.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scheduled_payment_fixtures.dart';

/// The fact Pencil's `Eyold` renders: a `once` template whose single
/// transaction already exists is terminada, not activa. The detail is the
/// only place that knows it, because it is the only place that counts the
/// generated transactions.
void main() {
  ScheduledPaymentDetail buildDetail({
    required ScheduledPaymentFrequency frequency,
    required int historyTotalCount,
    bool isDeleted = false,
  }) =>
      ScheduledPaymentDetail(
        scheduledPayment: buildScheduledPayment(
          frequency: frequency,
          tombstonedAt: isDeleted ? DateTime(2026, 8) : null,
        ),
        accountName: 'Bancolombia',
        historyTotalCount: historyTotalCount,
        // No skipped events in these cases, so the generated-transaction count
        // equals the total; `onceAlreadyGenerated` keys off it.
        generatedTransactionCount: historyTotalCount,
      );

  test('un `once` sin transacción generada sigue activo', () {
    final detail = buildDetail(
      frequency: ScheduledPaymentFrequency.once,
      historyTotalCount: 0,
    );

    expect(detail.onceAlreadyGenerated, isFalse);
    expect(detail.isActive, isTrue);
  });

  test('un `once` con su transacción ya generada queda terminado', () {
    final detail = buildDetail(
      frequency: ScheduledPaymentFrequency.once,
      historyTotalCount: 1,
    );

    expect(detail.onceAlreadyGenerated, isTrue);
    expect(detail.isActive, isFalse);
  });

  test('una plantilla repetible con historial sigue activa', () {
    final detail = buildDetail(
      frequency: ScheduledPaymentFrequency.monthly,
      historyTotalCount: 12,
    );

    expect(detail.onceAlreadyGenerated, isFalse);
    expect(detail.isActive, isTrue);
  });

  test('una plantilla con lápida nunca está activa', () {
    final detail = buildDetail(
      frequency: ScheduledPaymentFrequency.monthly,
      historyTotalCount: 0,
      isDeleted: true,
    );

    expect(detail.isActive, isFalse);
  });
}
