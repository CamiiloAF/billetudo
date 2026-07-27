import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/empty_state.dart';
import 'package:billetudo/core/widgets/error_state.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debts_summary.dart';
import 'package:billetudo/features/debts/presentation/cubit/debts_list_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debts_list_state.dart';
import 'package:billetudo/features/debts/presentation/pages/debts_list_page.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_card.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_card_skeleton.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_summary_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../debts_presentation_fixtures.dart';

class MockDebtsListCubit extends MockCubit<DebtsListState>
    implements DebtsListCubit {}

void main() {
  late MockDebtsListCubit cubit;

  final summary = DebtsSummary.from([
    buildDebtWithBalance(
      debt: buildDebt(id: 'd1', name: 'Crédito vehicular'),
      balance: buildBalance(totalIncreasesMinor: 4200000000, totalDecreasesMinor: 1344000000),
    ),
    buildDebtWithBalance(
      debt: buildDebt(id: 'd2', name: 'Le presté a Andrés', direction: DebtDirection.owedToMe),
      balance: buildBalance(totalIncreasesMinor: 40000000, totalDecreasesMinor: 15000000),
    ),
  ]);

  setUp(() => cubit = MockDebtsListCubit());

  Future<void> pump(
    WidgetTester tester,
    DebtsListState state, {
    ValueChanged<String>? onOpenDebt,
  }) async {
    // Tall surface so the four loading skeletons all lay out (a lazy ListView
    // would otherwise skip the ones below a 600pt fold).
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DebtsListCubit>.value(
          value: cubit,
          child: DebtsListPage(
            onAddDebt: () {},
            onOpenDebt: onOpenDebt ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('carga: 4 Debt Card Skeleton, sin lista ni error',
      (tester) async {
    await pump(tester, const DebtsListState());
    expect(find.byType(DebtCardSkeleton), findsNWidgets(4));
    expect(find.byType(DebtCard), findsNothing);
    expect(find.byType(ErrorState), findsNothing);
  });

  testWidgets('vacío: mensaje neutral y CTA "Agregar deuda"', (tester) async {
    await pump(
      tester,
      const DebtsListState(status: DebtsListStatus.ready),
    );
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Aún no tienes deudas registradas'), findsOneWidget);
    // Botón del header + CTA del estado vacío.
    expect(find.text('Agregar deuda'), findsOneWidget);
    expect(find.byType(DebtCardSkeleton), findsNothing);
  });

  testWidgets('con datos: summary card y una fila por deuda', (tester) async {
    await pump(
      tester,
      DebtsListState(status: DebtsListStatus.ready, summary: summary),
    );
    expect(find.byType(DebtSummaryCard), findsOneWidget);
    expect(find.byType(DebtCard), findsNWidgets(2));
    expect(find.text('Crédito vehicular'), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
  });

  testWidgets('error: ErrorState con recordatorio local-first y Reintentar',
      (tester) async {
    await pump(tester, const DebtsListState(status: DebtsListStatus.failure));
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('No pudimos cargar tus deudas'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('Reintentar vuelve a pedir la carga', (tester) async {
    when(cubit.start).thenAnswer((_) async {});
    await pump(tester, const DebtsListState(status: DebtsListStatus.failure));
    await tester.tap(find.text('Reintentar'));
    verify(cubit.start).called(1);
  });

  testWidgets('tocar una deuda la abre', (tester) async {
    String? opened;
    await pump(
      tester,
      DebtsListState(status: DebtsListStatus.ready, summary: summary),
      onOpenDebt: (id) => opened = id,
    );
    await tester.tap(find.text('Crédito vehicular'));
    expect(opened, 'd1');
  });
}
