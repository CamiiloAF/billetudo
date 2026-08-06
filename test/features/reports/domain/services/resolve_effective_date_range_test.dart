import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/domain/services/resolve_effective_date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolve = ResolveEffectiveDateRange();

  test('no clamp and monthly granularity for a normal multi-month range', () {
    final bounds = resolve(
      requested: DateRange(
        start: DateTime(2026, 1),
        endExclusive: DateTime(2026, 7),
        granularity: DateGranularity.monthly,
      ),
      earliestDataDate: DateTime(2025),
    );

    expect(bounds.isClamped, isFalse);
    expect(bounds.isDailyGranularity, isFalse);
    expect(bounds.effectiveRange.start, DateTime(2026, 1));
    expect(bounds.effectiveRange.granularity, DateGranularity.monthly);
  });

  test('clamps the start to the earliest data date and switches to daily '
      'when the effective span is short (HU-06 historial insuficiente)', () {
    final bounds = resolve(
      requested: DateRange(
        start: DateTime(2025),
        endExclusive: DateTime(2026),
        granularity: DateGranularity.monthly,
      ),
      earliestDataDate: DateTime(2025, 12, 28),
    );

    expect(bounds.isClamped, isTrue);
    expect(bounds.effectiveRange.start, DateTime(2025, 12, 28));
    expect(bounds.isDailyGranularity, isTrue);
    expect(bounds.effectiveRange.granularity, DateGranularity.daily);
  });

  test('no data at all: no clamp, granularity from the requested span', () {
    final bounds = resolve(
      requested: DateRange(
        start: DateTime(2026, 1),
        endExclusive: DateTime(2026, 7),
        granularity: DateGranularity.monthly,
      ),
      earliestDataDate: null,
    );

    expect(bounds.isClamped, isFalse);
    expect(bounds.earliestDataDate, isNull);
    expect(bounds.effectiveRange.granularity, DateGranularity.monthly);
  });

  test('defensively never lets the clamp push the start past the end', () {
    final bounds = resolve(
      requested: DateRange(
        start: DateTime(2026, 1),
        endExclusive: DateTime(2026, 2),
        granularity: DateGranularity.monthly,
      ),
      earliestDataDate: DateTime(2027),
    );

    expect(bounds.effectiveRange.start, bounds.effectiveRange.endExclusive);
  });

  test('a span exactly at the threshold stays monthly', () {
    final start = DateTime(2026, 1, 1);
    final end = start.add(
      const Duration(days: ResolveEffectiveDateRange.dailyGranularityThresholdDays),
    );
    final bounds = resolve(
      requested: DateRange(
        start: start,
        endExclusive: end,
        granularity: DateGranularity.monthly,
      ),
      earliestDataDate: start,
    );

    expect(bounds.isDailyGranularity, isFalse);
  });
}
