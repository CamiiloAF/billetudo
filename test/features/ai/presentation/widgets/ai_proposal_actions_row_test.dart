import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/ai/domain/entities/ai_action_proposal.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_action_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_action_state.dart';
import 'package:billetudo/features/ai/presentation/widgets/ai_proposal_actions_row.dart';
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

  Future<void> pumpRow(
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
            body: AiProposalActionsRow(
              messageId: 'msg-1',
              proposal: proposal,
              busy: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // Guards `_confirmedRowLabel`: each proposal kind's read-only confirmation
  // row names the entity it just created, never a generic label borrowed
  // from another kind.
  group('etiqueta de la fila confirmada, por tipo de propuesta', () {
    testWidgets('presupuesto: "Presupuesto creado"', (tester) async {
      await pumpRow(
        tester,
        buildBudgetProposal(status: AiProposalStatus.confirmed),
      );

      expect(find.text('Presupuesto creado'), findsOneWidget);
      expect(find.text('Meta creada'), findsNothing);
    });

    testWidgets('meta: "Meta creada"', (tester) async {
      await pumpRow(
        tester,
        buildGoalProposal(status: AiProposalStatus.confirmed),
      );

      expect(find.text('Meta creada'), findsOneWidget);
      expect(find.text('Presupuesto creado'), findsNothing);
    });

    testWidgets('categoría: "Categoría creada"', (tester) async {
      await pumpRow(
        tester,
        buildCategoryProposal(status: AiProposalStatus.confirmed),
      );

      expect(find.text('Categoría creada'), findsOneWidget);
      expect(find.text('Meta creada'), findsNothing);
    });

    testWidgets('transacción: "Ya está en tus movimientos"', (tester) async {
      await pumpRow(
        tester,
        buildTransactionProposal(status: AiProposalStatus.confirmed),
      );

      expect(find.text('Ya está en tus movimientos'), findsOneWidget);
      expect(find.text('Categoría creada'), findsNothing);
    });
  });
}
