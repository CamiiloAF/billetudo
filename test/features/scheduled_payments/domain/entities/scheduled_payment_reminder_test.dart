import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_reminder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scheduled_payment_fixtures.dart';

void main() {
  group('ScheduledPaymentReminder', () {
    test('las opciones ofrecidas son 0, 1, 3 y 7 días', () {
      expect(
        ScheduledPaymentReminder.values.map((option) => option.leadDays),
        [0, 1, 3, 7],
      );
    });

    test('null significa "sin recordatorio", no "sin configurar"', () {
      expect(ScheduledPaymentReminder.fromLeadDays(null), isNull);
    });

    test('un lead desconocido degrada a "sin recordatorio"', () {
      // Una fila escrita por una versión futura con una opción que este build
      // no conoce no puede tumbar la pantalla.
      expect(ScheduledPaymentReminder.fromLeadDays(2), isNull);
      expect(ScheduledPaymentReminder.isSupportedLead(2), isFalse);
    });

    test('resuelve cada lead ofrecido a su opción', () {
      expect(
        ScheduledPaymentReminder.fromLeadDays(3),
        ScheduledPaymentReminder.threeDaysBefore,
      );
    });
  });

  group('ScheduledPaymentDraft', () {
    test('acepta un lead ofrecido y lo conserva', () {
      final draft = buildExpenseDraft().copyWithReminder(7);

      final validated = draft.validated();

      expect(validated.isRight(), isTrue);
      expect(
        validated.getOrElse((_) => draft).reminderLeadDays,
        7,
      );
    });

    test('acepta "sin recordatorio" (null), que es el default', () {
      final validated = buildExpenseDraft().validated();

      expect(validated.isRight(), isTrue);
      expect(validated.getOrElse((_) => buildExpenseDraft()).reminderLeadDays,
          isNull);
    });

    test('rechaza un lead que la UI no puede representar', () {
      final validated = buildExpenseDraft().copyWithReminder(2).validated();

      expect(validated.isLeft(), isTrue);
      final failure = validated.getLeft().toNullable();
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure! as ValidationFailure).field,
        ScheduledPaymentDraft.fieldReminderLeadDays,
      );
    });
  });
}

extension on ScheduledPaymentDraft {
  ScheduledPaymentDraft copyWithReminder(int? reminderLeadDays) =>
      ScheduledPaymentDraft(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        categoryKind: categoryKind,
        amountMinor: amountMinor,
        currency: currency,
        type: type,
        note: note,
        transferAccountId: transferAccountId,
        frequency: frequency,
        interval: interval,
        nextDate: nextDate,
        endDate: endDate,
        requiresConfirmation: requiresConfirmation,
        tagIds: tagIds,
        debtId: debtId,
        goalId: goalId,
        reminderLeadDays: reminderLeadDays,
      );
}
