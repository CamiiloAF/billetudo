import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/ai/domain/usecases/watch_ai_messages.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_conversation_read_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_conversation_read_state.dart';
import 'package:billetudo/features/debts/domain/entities/debt_with_balance.dart';
import 'package:billetudo/features/debts/domain/entities/debts_summary.dart';
import 'package:billetudo/features/debts/domain/usecases/watch_debts.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../ai_fixtures.dart';

class MockWatchAiMessages extends Mock implements WatchAiMessages {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockWatchDebts extends Mock implements WatchDebts {}

void main() {
  late MockWatchAiMessages watchAiMessages;
  late MockWatchAccounts watchAccounts;
  late MockWatchDebts watchDebts;

  setUp(() {
    watchAiMessages = MockWatchAiMessages();
    watchAccounts = MockWatchAccounts();
    watchDebts = MockWatchDebts();

    when(watchAccounts.call)
        .thenAnswer((_) => Stream.value(const Right(<AccountWithBalance>[])));
    when(watchDebts.call).thenAnswer(
      (_) => Stream.value(
        Right(DebtsSummary.from(const <DebtWithBalance>[])),
      ),
    );
  });

  AiConversationReadCubit build() => AiConversationReadCubit(
        watchAiMessages,
        watchAccounts,
        watchDebts,
      );

  blocTest<AiConversationReadCubit, AiConversationReadState>(
    // This is the whole point of the read-only path: reading a thread never
    // touches AiConsentCubit or AiChatCubit — this cubit's constructor
    // simply has no dependency capable of sending a message, so there is
    // nothing to gate.
    'loads a thread\'s messages without any consent- or send-related '
    'dependency',
    setUp: () => when(() => watchAiMessages('conv-1')).thenAnswer(
      (_) => Stream.value(Right([buildAiMessage(id: 'm1')])),
    ),
    build: build,
    act: (cubit) => cubit.start('conv-1'),
    skip: 1,
    expect: () => [
      isA<AiConversationReadState>()
          .having(
            (s) => s.status,
            'status',
            AiConversationReadStatus.ready,
          )
          .having((s) => s.messages.length, 'messages', 1),
    ],
  );

  blocTest<AiConversationReadCubit, AiConversationReadState>(
    'a stream failure lands on failure with the cause',
    setUp: () => when(() => watchAiMessages('conv-1')).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    ),
    build: build,
    act: (cubit) => cubit.start('conv-1'),
    skip: 1,
    expect: () => [
      isA<AiConversationReadState>()
          .having((s) => s.status, 'status', AiConversationReadStatus.failure)
          .having((s) => s.failure, 'failure', isNotNull),
    ],
  );
}
