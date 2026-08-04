import 'package:equatable/equatable.dart';

/// How a [DateRange] buckets its points. `monthly` is the default
/// (HU-01/HU-02); `daily` is used when history is too short for monthly
/// buckets to be meaningful (HU-06 "historial insuficiente") — decided by
/// `resolveEffectiveDateRange`, never chosen directly by the caller.
enum DateGranularity { monthly, daily }

/// An explicit, half-open date window `[start, endExclusive)` plus its
/// bucketing granularity. Parameter of every report use case/repository
/// method from day 1 (HU-01, "Costura para Nivel 1/2") — this is what lets a
/// future "comparar con el periodo anterior" (Nivel 1) reuse the data layer
/// without rewriting it.
///
/// Dates are compared as local wall-clock `DateTime`s, consistent with how
/// `Transactions.date` is captured (see "Reglas de conteo" → Fechas y
/// agregación in `docs/requirements/10-graficas-informes.md`).
class DateRange extends Equatable {
  const DateRange({
    required this.start,
    required this.endExclusive,
    required this.granularity,
  });

  final DateTime start;
  final DateTime endExclusive;
  final DateGranularity granularity;

  DateRange copyWith({
    DateTime? start,
    DateTime? endExclusive,
    DateGranularity? granularity,
  }) =>
      DateRange(
        start: start ?? this.start,
        endExclusive: endExclusive ?? this.endExclusive,
        granularity: granularity ?? this.granularity,
      );

  @override
  List<Object?> get props => [start, endExclusive, granularity];
}
