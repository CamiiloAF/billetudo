import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/pending_occurrences_page.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_pending_row.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';

class MockPendingOccurrencesCubit extends MockCubit<PendingOccurrencesState>
    implements PendingOccurrencesCubit {}

/// AC9 (gap documentado en docs/dev-runs/pagos-programados.md): la UI real
/// de "Por confirmar" no debe exponer ningún gesto de un toque que omita una
/// ocurrencia — omitir solo debe alcanzarse abriendo la hoja de confirmación
/// (tocando la fila entera, que abre `ConfirmationSheet`).
void main() {
  late MockPendingOccurrencesCubit cubit;

  setUp(() {
    cubit = MockPendingOccurrencesCubit();
  });

  Future<void> pumpPage(WidgetTester tester, PendingOccurrencesState state) async {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<PendingOccurrencesState>.empty());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<PendingOccurrencesCubit>.value(
          value: cubit,
          child: const PendingOccurrencesPage(),
        ),
      ),
    );
  }

  testWidgets(
      'la lista de pendientes no contiene ningún Dismissible ni acción de '
      'omitir de un toque por fila', (tester) async {
    final items = [
      buildPendingOccurrence(
        scheduledPayment: buildScheduledPayment(requiresConfirmation: true),
      ),
      buildPendingOccurrence(
        occurrence: buildOccurrence(id: 'occ-2'),
        scheduledPayment: buildScheduledPayment(id: 'sp-2', requiresConfirmation: true),
        accountName: 'Nequi',
      ),
    ];

    await pumpPage(
      tester,
      PendingOccurrencesState(status: PendingOccurrencesStatus.ready, items: items),
    );

    expect(find.byType(ScheduledPendingRow), findsNWidgets(2));
    expect(find.byType(Dismissible), findsNothing);
    // No dedicated skip icon rendered directly on the pending list — the
    // skip action only exists inside the confirmation sheet, which is not
    // open here.
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('"Revisar todas" es el único atajo de lote, y sigue exigiendo la hoja',
      (tester) async {
    final items = [buildPendingOccurrence()];

    await pumpPage(
      tester,
      PendingOccurrencesState(status: PendingOccurrencesStatus.ready, items: items),
    );

    expect(find.widgetWithText(OutlinedButton, 'Revisar todas'), findsOneWidget);
  });

  testWidgets('estado vacío no renderiza ninguna fila ni acción de omitir',
      (tester) async {
    await pumpPage(
      tester,
      const PendingOccurrencesState(status: PendingOccurrencesStatus.ready),
    );

    expect(find.byType(ScheduledPendingRow), findsNothing);
    expect(find.byType(Dismissible), findsNothing);
  });
}
