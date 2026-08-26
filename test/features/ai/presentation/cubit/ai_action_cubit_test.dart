import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/ai/domain/entities/ai_action_outcome.dart';
import 'package:billetudo/features/ai/domain/entities/ai_action_proposal.dart';
import 'package:billetudo/features/ai/domain/usecases/execute_ai_action.dart';
import 'package:billetudo/features/ai/domain/usecases/update_ai_proposal_status.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_action_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_action_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../ai_fixtures.dart';

class MockExecuteAiAction extends Mock implements ExecuteAiAction {}

class MockUpdateAiProposalStatus extends Mock
    implements UpdateAiProposalStatus {}

void main() {
  late MockExecuteAiAction executeAiAction;
  late MockUpdateAiProposalStatus updateAiProposalStatus;

  setUp(() {
    executeAiAction = MockExecuteAiAction();
    updateAiProposalStatus = MockUpdateAiProposalStatus();
    registerFallbackValue(buildBudgetProposal());
  });

  AiActionCubit build() =>
      AiActionCubit(executeAiAction, updateAiProposalStatus);

  final proposal = buildBudgetProposal(id: 'p-1');

  blocTest<AiActionCubit, AiActionState>(
    'confirm() marks pending then clears it once the write lands',
    setUp: () {
      when(() => executeAiAction(proposal)).thenAnswer(
        (_) async => const Right(
          AiActionOutcome(
            proposalId: 'p-1',
            entity: AiActionEntity.budget,
            entityId: 'budget-1',
          ),
        ),
      );
      when(
        () => updateAiProposalStatus(
          messageId: 'msg-1',
          proposalId: 'p-1',
          status: AiProposalStatus.confirmed,
        ),
      ).thenAnswer((_) async => const Right(unit));
    },
    build: build,
    act: (cubit) => cubit.confirm(messageId: 'msg-1', proposal: proposal),
    expect: () => [
      isA<AiActionState>()
          .having((s) => s.pendingProposalId, 'pendingProposalId', 'p-1'),
      isA<AiActionState>()
          .having((s) => s.pendingProposalId, 'pendingProposalId', isNull),
    ],
    verify: (_) {
      verify(
        () => updateAiProposalStatus(
          messageId: 'msg-1',
          proposalId: 'p-1',
          status: AiProposalStatus.confirmed,
        ),
      ).called(1);
    },
  );

  blocTest<AiActionCubit, AiActionState>(
    'confirm() persists failed and surfaces the failure when the write blows up',
    setUp: () {
      when(() => executeAiAction(proposal)).thenAnswer(
        (_) async => const Left(DatabaseFailure('boom')),
      );
      when(
        () => updateAiProposalStatus(
          messageId: 'msg-1',
          proposalId: 'p-1',
          status: AiProposalStatus.failed,
        ),
      ).thenAnswer((_) async => const Right(unit));
    },
    build: build,
    act: (cubit) => cubit.confirm(messageId: 'msg-1', proposal: proposal),
    expect: () => [
      isA<AiActionState>()
          .having((s) => s.pendingProposalId, 'pendingProposalId', 'p-1'),
      isA<AiActionState>()
          .having((s) => s.pendingProposalId, 'pendingProposalId', isNull)
          .having((s) => s.failure, 'failure', isNotNull),
    ],
    verify: (_) {
      verify(
        () => updateAiProposalStatus(
          messageId: 'msg-1',
          proposalId: 'p-1',
          status: AiProposalStatus.failed,
        ),
      ).called(1);
    },
  );

  test('dismiss() only persists the status, never executes a write', () async {
    when(
      () => updateAiProposalStatus(
        messageId: 'msg-1',
        proposalId: 'p-1',
        status: AiProposalStatus.dismissed,
      ),
    ).thenAnswer((_) async => const Right(unit));
    final cubit = build();

    await cubit.dismiss(messageId: 'msg-1', proposal: proposal);

    verifyNever(() => executeAiAction(any()));
    verify(
      () => updateAiProposalStatus(
        messageId: 'msg-1',
        proposalId: 'p-1',
        status: AiProposalStatus.dismissed,
      ),
    ).called(1);
  });
}
