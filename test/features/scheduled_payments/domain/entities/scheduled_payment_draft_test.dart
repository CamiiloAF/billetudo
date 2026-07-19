import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scheduled_payment_fixtures.dart';

void main() {
  group('ScheduledPaymentDraft.validated (HU-01)', () {
    test('acepta un gasto válido y normaliza la moneda', () {
      final result = buildExpenseDraft(currency: 'cop').validated();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()!.currency, 'COP');
    });

    test('rechaza sin cuenta', () {
      final result = buildExpenseDraft(accountId: '').validated();

      expect(
        (result.getLeft().toNullable()! as ValidationFailure).field,
        ScheduledPaymentDraft.fieldAccountId,
      );
    });

    test('rechaza monto no positivo', () {
      final result = buildExpenseDraft(amountMinor: 0).validated();

      expect(
        (result.getLeft().toNullable()! as ValidationFailure).field,
        ScheduledPaymentDraft.fieldAmountMinor,
      );
    });

    test('rechaza una categoría de kind income en un gasto', () {
      final result = ScheduledPaymentDraft(
        accountId: 'acc-1',
        categoryId: 'cat-1',
        categoryKind: CategoryKind.income,
        amountMinor: 1000,
        currency: 'COP',
        type: ScheduledPaymentType.expense,
        frequency: ScheduledPaymentFrequency.once,
        nextDate: DateTime(2026, 7, 15),
      ).validated();

      expect(
        (result.getLeft().toNullable()! as ValidationFailure).field,
        ScheduledPaymentDraft.fieldCategoryId,
      );
    });

    test('once ignora/normaliza interval a 1', () {
      final result = buildExpenseDraft(
        frequency: ScheduledPaymentFrequency.once,
        interval: 5,
      ).validated();

      expect(result.getRight().toNullable()!.interval, 1);
    });

    test('rechaza interval menor a 1 en una frecuencia repetible', () {
      final result = buildExpenseDraft(
        frequency: ScheduledPaymentFrequency.weekly,
        interval: 0,
      ).validated();

      expect(
        (result.getLeft().toNullable()! as ValidationFailure).field,
        ScheduledPaymentDraft.fieldInterval,
      );
    });

    test('rechaza endDate anterior a nextDate', () {
      final result = buildExpenseDraft(
        endDate: DateTime(2026, 7, 1),
      ).validated();

      expect(
        (result.getLeft().toNullable()! as ValidationFailure).field,
        ScheduledPaymentDraft.fieldEndDate,
      );
    });

    group('criterio 16: transfer', () {
      test('exige transferAccountId', () {
        final result = buildTransferDraft(transferAccountId: null).validated();

        expect(
          (result.getLeft().toNullable()! as ValidationFailure).field,
          ScheduledPaymentDraft.fieldTransferAccountId,
        );
      });

      test('rechaza origen y destino iguales', () {
        final result =
            buildTransferDraft(transferAccountId: 'acc-1').validated();

        expect(
          (result.getLeft().toNullable()! as ValidationFailure).field,
          ScheduledPaymentDraft.fieldTransferAccountId,
        );
      });

      test('nunca lleva categoría ni etiquetas, aunque el draft las traiga',
          () {
        final result = ScheduledPaymentDraft(
          accountId: 'acc-1',
          transferAccountId: 'acc-2',
          categoryId: 'cat-1',
          amountMinor: 1000,
          currency: 'COP',
          type: ScheduledPaymentType.transfer,
          frequency: ScheduledPaymentFrequency.once,
          nextDate: DateTime(2026, 7, 15),
          tagIds: const ['tag-1'],
        ).validated();

        final draft = result.getRight().toNullable()!;
        expect(draft.categoryId, isNull);
        expect(draft.tagIds, isEmpty);
      });
    });
  });
}
