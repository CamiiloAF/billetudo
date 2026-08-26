import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/utils/ai_client_context.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/ai/domain/entities/ai_message.dart';
import 'package:billetudo/features/ai/domain/entities/ai_tool_call.dart';
import 'package:billetudo/features/ai/domain/entities/ai_turn.dart';
import 'package:billetudo/features/ai/domain/usecases/append_ai_message.dart';
import 'package:billetudo/features/ai/domain/usecases/build_financial_snapshot.dart';
import 'package:billetudo/features/ai/domain/usecases/resolve_ai_tool_call.dart';
import 'package:billetudo/features/ai/domain/usecases/resume_or_create_ai_conversation.dart';
import 'package:billetudo/features/ai/domain/usecases/send_ai_turn.dart';
import 'package:billetudo/features/ai/domain/usecases/watch_ai_messages.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_chat_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_chat_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../ai_fixtures.dart';

class MockResumeOrCreateAiConversation extends Mock
    implements ResumeOrCreateAiConversation {}

class MockWatchAiMessages extends Mock implements WatchAiMessages {}

class MockAppendAiMessage extends Mock implements AppendAiMessage {}

class MockBuildFinancialSnapshot extends Mock
    implements BuildFinancialSnapshot {}

class MockSendAiTurn extends Mock implements SendAiTurn {}

class MockResolveAiToolCall extends Mock implements ResolveAiToolCall {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockAiClientContextProvider extends Mock
    implements AiClientContextProvider {}

void main() {
  late MockResumeOrCreateAiConversation resumeOrCreateAiConversation;
  late MockWatchAiMessages watchAiMessages;
  late MockAppendAiMessage appendAiMessage;
  late MockBuildFinancialSnapshot buildFinancialSnapshot;
  late MockSendAiTurn sendAiTurn;
  late MockResolveAiToolCall resolveAiToolCall;
  late MockWatchAccounts watchAccounts;
  late MockAiClientContextProvider clientContext;

  setUpAll(() {
    registerFallbackValue(
      const AiTurnRequest(
        conversationId: 'conv-1',
        locale: 'es-CO',
        timezone: 'UTC',
        clientVersion: '0.0.0+0',
        messages: <AiMessage>[],
      ),
    );
    registerFallbackValue(
      const AiToolCall(id: 't1', name: 'get_transactions', arguments: {}),
    );
    registerFallbackValue(buildAiMessage());
  });

  setUp(() {
    resumeOrCreateAiConversation = MockResumeOrCreateAiConversation();
    watchAiMessages = MockWatchAiMessages();
    appendAiMessage = MockAppendAiMessage();
    buildFinancialSnapshot = MockBuildFinancialSnapshot();
    sendAiTurn = MockSendAiTurn();
    resolveAiToolCall = MockResolveAiToolCall();
    watchAccounts = MockWatchAccounts();
    clientContext = MockAiClientContextProvider();

    when(watchAccounts.call)
        .thenAnswer((_) => Stream.value(const Right(<AccountWithBalance>[])));
    when(clientContext.resolve).thenAnswer(
      (_) async => const AiClientContext(
        locale: 'es-CO',
        timezone: 'America/Bogota',
        clientVersion: '0.0.0+0',
      ),
    );
    when(() => appendAiMessage(any()))
        .thenAnswer((_) async => const Right(unit));
    when(buildFinancialSnapshot.call)
        .thenAnswer((_) async => const Left(DatabaseFailure('no data')));
  });

  AiChatCubit build() => AiChatCubit(
        resumeOrCreateAiConversation,
        watchAiMessages,
        appendAiMessage,
        buildFinancialSnapshot,
        sendAiTurn,
        resolveAiToolCall,
        watchAccounts,
        clientContext,
      );

  blocTest<AiChatCubit, AiChatState>(
    'start() resumes the last thread and streams its messages',
    setUp: () {
      when(resumeOrCreateAiConversation.call)
          .thenAnswer((_) async => const Right('conv-1'));
      when(() => watchAiMessages('conv-1')).thenAnswer(
        (_) => Stream.value(Right([buildAiMessage(conversationId: 'conv-1')])),
      );
    },
    build: build,
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<AiChatState>()
          .having((s) => s.conversationId, 'conversationId', 'conv-1'),
      isA<AiChatState>()
          .having((s) => s.status, 'status', AiChatStatus.ready)
          .having((s) => s.messages.length, 'messages', 1),
    ],
  );

  blocTest<AiChatCubit, AiChatState>(
    'updateDraft sets the composer text',
    build: build,
    act: (cubit) => cubit.updateDraft('hola'),
    expect: () => [
      isA<AiChatState>().having((s) => s.draft, 'draft', 'hola'),
    ],
  );

  blocTest<AiChatCubit, AiChatState>(
    'send() persists the reply and returns to ready on a plain answer',
    setUp: () {
      when(resumeOrCreateAiConversation.call)
          .thenAnswer((_) async => const Right('conv-1'));
      when(() => watchAiMessages('conv-1'))
          .thenAnswer((_) => Stream.value(const Right(<AiMessage>[])));
      when(() => sendAiTurn(any())).thenAnswer(
        (_) async => const Right(
          AiTurnResponse(
            finishReason: AiFinishReason.message,
            content: 'listo',
          ),
        ),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.start();
      await Future<void>.delayed(Duration.zero);
      cubit.updateDraft('¿cuánto llevo gastado?');
      await cubit.send();
    },
    verify: (_) {
      // The pending user bubble, the assistant reply, and the user bubble's
      // own status update to sent.
      verify(() => appendAiMessage(any())).called(3);
      verify(() => sendAiTurn(any())).called(1);
    },
  );

  blocTest<AiChatCubit, AiChatState>(
    'send() resolves tool calls and resends once when the model needs data',
    setUp: () {
      when(resumeOrCreateAiConversation.call)
          .thenAnswer((_) async => const Right('conv-1'));
      when(() => watchAiMessages('conv-1'))
          .thenAnswer((_) => Stream.value(const Right(<AiMessage>[])));
      var call = 0;
      when(() => sendAiTurn(any())).thenAnswer((_) async {
        call++;
        if (call == 1) {
          return const Right(
            AiTurnResponse(
              finishReason: AiFinishReason.toolCalls,
              content: '',
              toolCalls: [
                AiToolCall(
                  id: 't1',
                  name: 'get_transactions',
                  arguments: {},
                ),
              ],
            ),
          );
        }
        return const Right(
          AiTurnResponse(
            finishReason: AiFinishReason.message,
            content: 'ya con los datos',
          ),
        );
      });
      when(() => resolveAiToolCall(any())).thenAnswer(
        (_) async => const Right(
          AiToolResult(toolCallId: 't1', name: 'get_transactions', result: {}),
        ),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.start();
      await Future<void>.delayed(Duration.zero);
      cubit.updateDraft('¿en qué gasté?');
      await cubit.send();
    },
    verify: (_) {
      verify(() => sendAiTurn(any())).called(2);
      verify(() => resolveAiToolCall(any())).called(1);
    },
  );
}
