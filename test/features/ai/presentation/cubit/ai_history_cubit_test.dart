import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/ai/domain/entities/ai_conversation.dart';
import 'package:billetudo/features/ai/domain/usecases/clear_ai_history.dart';
import 'package:billetudo/features/ai/domain/usecases/clear_all_ai_history.dart';
import 'package:billetudo/features/ai/domain/usecases/start_new_ai_conversation.dart';
import 'package:billetudo/features/ai/domain/usecases/watch_ai_conversations.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_history_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_history_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchAiConversations extends Mock implements WatchAiConversations {}

class MockStartNewAiConversation extends Mock
    implements StartNewAiConversation {}

class MockClearAiHistory extends Mock implements ClearAiHistory {}

class MockClearAllAiHistory extends Mock implements ClearAllAiHistory {}

AiConversation _conversation({String id = 'conv-1'}) => AiConversation(
      id: id,
      title: 'Presupuesto de comida de agosto',
      updatedAt: DateTime(2026, 8, 25),
      messageCount: 4,
    );

void main() {
  late MockWatchAiConversations watchAiConversations;
  late MockStartNewAiConversation startNewAiConversation;
  late MockClearAiHistory clearAiHistory;
  late MockClearAllAiHistory clearAllAiHistory;

  setUp(() {
    watchAiConversations = MockWatchAiConversations();
    startNewAiConversation = MockStartNewAiConversation();
    clearAiHistory = MockClearAiHistory();
    clearAllAiHistory = MockClearAllAiHistory();
  });

  AiHistoryCubit build() => AiHistoryCubit(
        watchAiConversations,
        startNewAiConversation,
        clearAiHistory,
        clearAllAiHistory,
      );

  blocTest<AiHistoryCubit, AiHistoryState>(
    'emits loading then ready with the conversations',
    setUp: () => when(watchAiConversations.call).thenAnswer(
      (_) => Stream.value(Right([_conversation()])),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [
      isA<AiHistoryState>()
          .having((s) => s.status, 'status', AiHistoryStatus.loading),
      isA<AiHistoryState>()
          .having((s) => s.status, 'status', AiHistoryStatus.ready)
          .having((s) => s.conversations.length, 'conversations', 1)
          .having((s) => s.isEmpty, 'isEmpty', false),
    ],
  );

  blocTest<AiHistoryCubit, AiHistoryState>(
    'an empty list stays ready but isEmpty',
    setUp: () => when(watchAiConversations.call)
        .thenAnswer((_) => Stream.value(const Right(<AiConversation>[]))),
    build: build,
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<AiHistoryState>()
          .having((s) => s.status, 'status', AiHistoryStatus.ready)
          .having((s) => s.isEmpty, 'isEmpty', true),
    ],
  );

  blocTest<AiHistoryCubit, AiHistoryState>(
    'a stream failure lands on failure with the cause',
    setUp: () => when(watchAiConversations.call).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<AiHistoryState>()
          .having((s) => s.status, 'status', AiHistoryStatus.failure)
          .having((s) => s.failure, 'failure', isNotNull),
    ],
  );

  test('startNewConversation returns the new id on success', () async {
    when(startNewAiConversation.call)
        .thenAnswer((_) async => const Right('conv-new'));
    final cubit = build();

    final id = await cubit.startNewConversation();

    expect(id, 'conv-new');
  });

  test('startNewConversation returns null on failure', () async {
    when(startNewAiConversation.call)
        .thenAnswer((_) async => const Left(DatabaseFailure('boom')));
    final cubit = build();

    final id = await cubit.startNewConversation();

    expect(id, isNull);
  });

  test('deleteConversation forwards the id to ClearAiHistory', () async {
    when(() => clearAiHistory('conv-1'))
        .thenAnswer((_) async => const Right(unit));
    final cubit = build();

    await cubit.deleteConversation('conv-1');

    verify(() => clearAiHistory('conv-1')).called(1);
  });

  test('deleteAll forwards to ClearAllAiHistory', () async {
    when(clearAllAiHistory.call).thenAnswer((_) async => const Right(unit));
    final cubit = build();

    await cubit.deleteAll();

    verify(clearAllAiHistory.call).called(1);
  });
}
