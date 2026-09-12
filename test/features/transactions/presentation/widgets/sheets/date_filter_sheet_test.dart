import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/date_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/date_filter_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../categories/presentation/widgets/pump_widget.dart';

class MockDateFilterCubit extends MockCubit<DateFilterState>
    implements DateFilterCubit {}

void main() {
  late MockDateFilterCubit cubit;

  setUp(() {
    cubit = MockDateFilterCubit();
    when(() => cubit.clearToThisMonth()).thenReturn(null);
  });

  Future<void> pump(WidgetTester tester, DatePeriodFilter filter) async {
    when(() => cubit.state).thenReturn(DateFilterState(filter: filter));
    await tester.pumpAppWidget(
      BlocProvider<DateFilterCubit>.value(
        value: cubit,
        child: const DateFilterSheetBody(),
      ),
    );
  }

  testWidgets('sin rango personalizado no muestra el botón de limpiar fila', (
    tester,
  ) async {
    await pump(tester, DatePeriodFilter.thisMonth(DateTime(2026, 7, 15)));

    expect(find.byIcon(LucideIcons.x), findsNothing);
  });

  testWidgets(
    'con rango personalizado seleccionado muestra la x en el chip',
    (tester) async {
      await pump(
        tester,
        DatePeriodFilter.custom(
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 15),
        ),
      );

      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    },
  );

  testWidgets('tocar la x del chip limpia solo ese filtro, sin abrir el picker',
      (
    tester,
  ) async {
    await pump(
      tester,
      DatePeriodFilter.custom(
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 15),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pump();

    verify(() => cubit.clearToThisMonth()).called(1);
    // The date range picker sheet never opened: its "Aplicar" CTA is absent.
    expect(find.text('Aplicar'), findsOneWidget);
  });
}
