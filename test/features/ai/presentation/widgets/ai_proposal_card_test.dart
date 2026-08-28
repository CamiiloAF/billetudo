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
  });
}
