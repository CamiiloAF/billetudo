import 'package:billetudo/core/l10n/gen/app_localizations_es.dart';
import 'package:billetudo/features/scheduled_payments/presentation/utils/scheduled_payment_format.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Vence hoy" only means *today*: a date already in the past reads "hace N
/// días" instead, so a historical detail never claims something overdue for
/// weeks is due right now.
void main() {
  final l10n = AppLocalizationsEs();
  final today = DateTime(2026, 7, 26);

  String labelFor(DateTime date) =>
      ScheduledPaymentFormat.dueInLabel(l10n, date, today: today);

  test('hoy mismo', () {
    expect(labelFor(DateTime(2026, 7, 26, 23)), 'Vence hoy');
  });

  test('futuro', () {
    expect(labelFor(DateTime(2026, 7, 27)), 'en 1 día');
    expect(labelFor(DateTime(2026, 8, 22)), 'en 27 días');
  });

  test('pasado: cuenta hacia atrás, no colapsa en "Vence hoy"', () {
    expect(labelFor(DateTime(2026, 7, 25)), 'hace 1 día');
    expect(labelFor(DateTime(2026, 6, 26)), 'hace 30 días');
  });
}
