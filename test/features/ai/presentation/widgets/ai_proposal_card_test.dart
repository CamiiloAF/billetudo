import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/ai/domain/entities/ai_action_proposal.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_action_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_action_state.dart';
import 'package:billetudo/features/ai/presentation/widgets/ai_proposal_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ai_fixtures.dart';

class MockAiActionCubit extends MockCubit<AiActionState>
    implements AiActionCubit {}

void main() {
  late MockAiActionCubit actionCubit;

  setUp(() {
    actionCubit = MockAiActionCubit();
    whenListen(
      actionCubit,
      const Stream<AiActionState>.empty(),
      initialState: const AiActionState(),
    );
  });

  Future<void> pumpCard(
    WidgetTester tester,
    AiActionProposal proposal,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: BlocProvider<AiActionCubit>.value(
          value: actionCubit,
          child: Scaffold(
            body: AiProposalCard(
              messageId: 'msg-1',
              proposal: proposal,
              accountNames: const {'acc-1': 'Nequi'},
              debtNames: const {
                'debt-1': 'Crédito moto',
                'debt-largo': 'Crédito hipotecario Bancolombia tasa fija 2024',
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // Guards `_confirmedFootnote`: each proposal kind must name the entity it
  // just created (bugfix-adjacent gap — the card used to have zero widget
  // coverage), never a generic "transactions" copy borrowed from another
  // kind.
  group('pie de página confirmado, por tipo de propuesta', () {
    testWidgets('presupuesto: "Tu presupuesto ya está creado."', (
      tester,
    ) async {
      await pumpCard(
        tester,
        buildBudgetProposal(status: AiProposalStatus.confirmed),
      );

      expect(find.text('Tu presupuesto ya está creado.'), findsOneWidget);
      expect(find.text('Tu meta ya está creada.'), findsNothing);
      expect(find.text('Tu categoría ya está creada.'), findsNothing);
      expect(find.text('Aplicado a tus movimientos.'), findsNothing);
    });

    testWidgets('meta: "Tu meta ya está creada."', (tester) async {
      await pumpCard(
        tester,
        buildGoalProposal(status: AiProposalStatus.confirmed),
      );

      expect(find.text('Tu meta ya está creada.'), findsOneWidget);
      expect(find.text('Tu presupuesto ya está creado.'), findsNothing);
    });

    testWidgets('categoría: "Tu categoría ya está creada."', (tester) async {
      await pumpCard(
        tester,
        buildCategoryProposal(status: AiProposalStatus.confirmed),
      );

      expect(find.text('Tu categoría ya está creada.'), findsOneWidget);
      expect(find.text('Tu meta ya está creada.'), findsNothing);
    });

    testWidgets('transacción: "Aplicado a tus movimientos."', (
      tester,
    ) async {
      await pumpCard(
        tester,
        buildTransactionProposal(status: AiProposalStatus.confirmed),
      );

      expect(find.text('Aplicado a tus movimientos.'), findsOneWidget);
      expect(find.text('Tu categoría ya está creada.'), findsNothing);
    });

    testWidgets('atribución a deuda: "El movimiento ya cuenta en tu deuda."',
        (tester) async {
      await pumpCard(
        tester,
        buildDebtLinkProposal(status: AiProposalStatus.confirmed),
      );

      expect(
        find.text('El movimiento ya cuenta en tu deuda.'),
        findsOneWidget,
      );
      expect(find.text('Aplicado a tus movimientos.'), findsNothing);
    });
  });

  // Confirmar a ciegas un vínculo que no se ve es lo que erosiona la confianza
  // en las propuestas: si la tarjeta no nombra la deuda, no hay nada que
  // confirmar informadamente.
  group('atribución a una deuda', () {
    testWidgets('un movimiento propuesto con deuda la nombra en la tarjeta',
        (tester) async {
      await pumpCard(
        tester,
        buildTransactionProposal(debtId: 'debt-1'),
      );

      expect(find.text('Deuda'), findsOneWidget);
      expect(find.text('Crédito moto'), findsOneWidget);
    });

    testWidgets('sin deuda no aparece la fila', (tester) async {
      await pumpCard(tester, buildTransactionProposal());

      expect(find.text('Deuda'), findsNothing);
    });

    testWidgets('una deuda que el dispositivo no resuelve usa una etiqueta '
        'genérica, nunca el id crudo', (tester) async {
      await pumpCard(
        tester,
        buildTransactionProposal(debtId: 'debt-desconocida'),
      );

      expect(find.text('Deuda seleccionada'), findsOneWidget);
      expect(find.text('debt-desconocida'), findsNothing);
    });

    testWidgets('la tarjeta de vínculo dice que no crea ni mueve nada',
        (tester) async {
      await pumpCard(tester, buildDebtLinkProposal());

      expect(find.text('Crédito moto'), findsOneWidget);
      expect(
        find.textContaining('No se crea ningún movimiento nuevo'),
        findsOneWidget,
      );
    });

    testWidgets('un nombre de deuda largo se trunca en vez de desbordar',
        (tester) async {
      await pumpCard(
        tester,
        buildDebtLinkProposal(debtId: 'debt-largo'),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
