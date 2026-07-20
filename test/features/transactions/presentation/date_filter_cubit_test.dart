import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/date_filter_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('granularidad y stepper (HU-06b): aplican de inmediato', () {
    blocTest<DateFilterCubit, DateFilterState>(
      'cambiar la granularidad salta al periodo que contiene la fecha activa',
      build: DateFilterCubit.new,
      act: (cubit) async {
        cubit.start(DatePeriodFilter.granular(
            DateGranularity.month, DateTime(2026, 7, 15)));
        cubit.granularitySelected(DateGranularity.year);
      },
      verify: (cubit) {
        expect(cubit.state.filter.granularity, DateGranularity.year);
        expect(cubit.state.filter.start, DateTime(2026));
      },
    );

    blocTest<DateFilterCubit, DateFilterState>(
      'un paso adelante mueve el periodo activo',
      build: DateFilterCubit.new,
      act: (cubit) async {
        cubit.start(DatePeriodFilter.granular(
            DateGranularity.month, DateTime(2026, 7, 15)));
        cubit.step(1);
      },
      verify: (cubit) => expect(cubit.state.filter.start, DateTime(2026, 8)),
    );
  });

  group('rango personalizado (HU-06b)', () {
    blocTest<DateFilterCubit, DateFilterState>(
      'solo se aplica cuando el llamador confirma con Aplicar',
      build: DateFilterCubit.new,
      act: (cubit) => cubit.applyCustomRange(
        start: DateTime(2026),
        end: DateTime(2026, 1, 15),
      ),
      verify: (cubit) {
        expect(cubit.state.filter.isCustomRange, isTrue);
        expect(cubit.state.filter.start, DateTime(2026));
      },
    );

    blocTest<DateFilterCubit, DateFilterState>(
      'la "X" siempre regresa a Este mes, nunca a "sin filtro"',
      build: DateFilterCubit.new,
      act: (cubit) {
        cubit.applyCustomRange(
          start: DateTime(2026),
          end: DateTime(2026, 1, 15),
        );
        cubit.clearToThisMonth();
      },
      verify: (cubit) => expect(cubit.state.filter.isCustomRange, isFalse),
    );
  });
}
