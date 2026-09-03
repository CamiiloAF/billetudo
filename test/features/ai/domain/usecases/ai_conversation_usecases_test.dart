import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/ai/domain/entities/ai_access.dart';
import 'package:billetudo/features/ai/domain/entities/ai_action_proposal.dart';
import 'package:billetudo/features/ai/domain/entities/ai_report.dart';
import 'package:billetudo/features/ai/domain/entities/ai_turn.dart';
import 'package:billetudo/features/ai/domain/repositories/ai_history_repository.dart';
import 'package:billetudo/features/ai/domain/repositories/ai_report_repository.dart';
import 'package:billetudo/features/ai/domain/repositories/ai_repository.dart';
import 'package:billetudo/features/ai/domain/usecases/append_ai_message.dart';
import 'package:billetudo/features/ai/domain/usecases/check_ai_access.dart';
import 'package:billetudo/features/ai/domain/usecases/clear_ai_history.dart';
import 'package:billetudo/features/ai/domain/usecases/report_ai_message.dart';
import 'package:billetudo/features/ai/domain/usecases/send_ai_turn.dart';
import 'package:billetudo/features/ai/domain/usecases/start_new_ai_conversation.dart';
import 'package:billetudo/features/ai/domain/usecases/update_ai_proposal_status.dart';
import 'package:billetudo/features/ai/domain/usecases/watch_ai_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../ai_fixtures.dart';

class MockAiRepository extends Mock implements AiRepository {}

class MockAiHistoryRepository extends Mock implements AiHistoryRepository {}

class MockAiReportRepository extends Mock implements AiReportRepository {}

class FakeAiTurnRequest extends Fake implements AiTurnRequest {}

/// The thin use cases that only exist so presentation never reaches for a
/// repository. What they must get right is the wiring — in particular, not
/// transposing the two ids of a proposal update.
void main() {
  late MockAiRepository ai;
  late MockAiHistoryRepository history;
  late MockAiReportRepository reports;

  setUpAll(() {
    registerFallbackValue(FakeAiTurnRequest());
    registerFallbackValue(buildAiMessage());
    registerFallbackValue(AiProposalStatus.pending);
    registerFallbackValue(
      const AiReport(
        reason: AiReportReason.other,
        reportedText: 'fallback',
        clientVersion: '0.0.0',
      ),
    );
  });

  setUp(() {
    ai = MockAiRepository();
    history = MockAiHistoryRepository();
    reports = MockAiReportRepository();
  });

  test('SendAiTurn hands the request to the broker untouched', () async {
    final request = AiTurnRequest(
      conversationId: 'conv-1',
      locale: 'es-CO',
      timezone: 'America/Bogota',
      clientVersion: '1.12.0+134',
      messages: [buildAiMessage()],
    );
    const response = AiTurnResponse(
      finishReason: AiFinishReason.message,
      content: 'listo',
    );
    when(() => ai.sendTurn(any())).thenAnswer((_) async => const Right(response));

    final result = await SendAiTurn(ai)(request);

    expect(result.getRight().toNullable(), response);
    verify(() => ai.sendTurn(request)).called(1);
  });

  test('CheckAiAccess returns the server verdict as is', () async {
    when(ai.checkAccess)
        .thenAnswer((_) async => const Right(AiAccess(allowed: true)));

    final access = (await CheckAiAccess(ai)()).getRight().toNullable()!;

    expect(access.allowed, isTrue);
  });

  test('CheckAiAccess propagates a failure instead of guessing a verdict',
      () async {
    when(ai.checkAccess).thenAnswer(
      (_) async => const Left(NetworkFailure('unreachable')),
    );

    final result = await CheckAiAccess(ai)();

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
  });

  test('WatchAiMessages streams the thread it was asked for', () async {
    final messages = [buildAiMessage()];
    when(() => history.watchMessages('conv-1'))
        .thenAnswer((_) => Stream.value(Right(messages)));

    final emitted = await WatchAiMessages(history)('conv-1').first;

    expect(emitted.getRight().toNullable(), messages);
  });

  test('AppendAiMessage persists the bubble it was given', () async {
    final message = buildAiMessage(id: 'm9');
    when(() => history.append(any())).thenAnswer((_) async => const Right(unit));

    await AppendAiMessage(history)(message);

    verify(() => history.append(message)).called(1);
  });

  test('UpdateAiProposalStatus forwards each id to its own parameter',
      () async {
    when(
      () => history.updateProposalStatus(
        messageId: any(named: 'messageId'),
        proposalId: any(named: 'proposalId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    await UpdateAiProposalStatus(history)(
      messageId: 'm1',
      proposalId: 'tc_0_0',
      status: AiProposalStatus.confirmed,
    );

    verify(
      () => history.updateProposalStatus(
        messageId: 'm1',
        proposalId: 'tc_0_0',
        status: AiProposalStatus.confirmed,
      ),
    ).called(1);
  });

  test('StartNewAiConversation always opens a brand-new thread', () async {
    when(history.startNewConversation)
        .thenAnswer((_) async => const Right('conv-7'));

    final id = (await StartNewAiConversation(history)())
        .getRight()
        .toNullable();

    expect(id, 'conv-7');
  });

  test('ClearAiHistory erases the thread it was pointed at', () async {
    when(() => history.clear(any())).thenAnswer((_) async => const Right(unit));

    await ClearAiHistory(history)('conv-1');

    verify(() => history.clear('conv-1')).called(1);
  });

  test('ReportAiMessage files the report the person composed', () async {
    const report = AiReport(
      reason: AiReportReason.harmful,
      reportedText: 'texto reportado',
      clientVersion: '1.12.0+134',
    );
    when(() => reports.report(any())).thenAnswer((_) async => const Right(unit));

    await ReportAiMessage(reports)(report);

    verify(() => reports.report(report)).called(1);
  });
}
