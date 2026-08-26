import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart' show AppDatabase;
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/ai/data/datasources/ai_history_local_datasource.dart';
import 'package:billetudo/features/ai/data/repositories/ai_history_repository_impl.dart';
import 'package:billetudo/features/ai/domain/entities/ai_action_proposal.dart';
import 'package:billetudo/features/ai/domain/entities/ai_message.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../ai_fixtures.dart';

class MockAiHistoryLocalDatasource extends Mock
    implements AiHistoryLocalDatasource {}

/// A Drift failure carrying the SQL and its bound values — which for this
/// table means the text of somebody's message.
class FakeDriftException implements Exception {
  const FakeDriftException();

  @override
  String toString() =>
      'SqliteException: near "INSERT": ai_messages, with args '
      '[me gasté la plata en el bar]';
}

/// Records what would have been uploaded, so a test can assert that no
/// conversation content ever reaches the crash reporter.
class RecordingCrashReporter implements CrashReporter {
  final List<Object> errors = <Object>[];
  final List<Failure> failures = <Failure>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) async {
    errors.add(error);
  }

  @override
  Future<void> recordFailure(Failure failure, {String? context}) async {
    failures.add(failure);
  }

  @override
  Future<void> init() async {}

  @override
  void log(String message, {String? category}) {}

  @override
  Future<void> setUser(String id) async {}

  @override
  Future<void> clearUser() async {}
}

void main() {
  late AppDatabase database;
  late RecordingCrashReporter crash;
  late AiHistoryRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    crash = RecordingCrashReporter();
    repository = AiHistoryRepositoryImpl(
      AiHistoryLocalDatasource(database),
      crash,
    );
  });

  tearDown(() async => database.close());

  group('append and watch', () {
    test('a thread comes back oldest first with its cards attached', () async {
      await repository.append(
        buildAiMessage(
          id: 'm1',
          role: AiMessageRole.user,
          content: '¿me alcanza para un presupuesto de comida?',
          createdAt: DateTime(2026, 8, 25, 9),
          status: AiMessageStatus.sent,
        ),
      );
      await repository.append(
        buildAiMessage(
          id: 'm2',
          content: 'Te propongo esto',
          createdAt: DateTime(2026, 8, 25, 9, 1),
          proposals: [buildBudgetProposal()],
        ),
      );

      final messages = (await repository.watchMessages('conv-1').first)
          .getRight()
          .toNullable()!;

      expect(messages.map((message) => message.id), ['m1', 'm2']);
      expect(messages.first.role, AiMessageRole.user);
      expect(messages.last.proposals.single, buildBudgetProposal());
    });

    test('a message with no cards stores no proposals payload', () async {
      await repository.append(buildAiMessage(id: 'm1'));

      final messages = (await repository.watchMessages('conv-1').first)
          .getRight()
          .toNullable()!;

      expect(messages.single.proposals, isEmpty);
    });

    test('re-appending a user bubble after the turn lands does not duplicate '
        'it', () async {
      final pending = buildAiMessage(
        id: 'm1',
        role: AiMessageRole.user,
        content: 'hola',
        status: AiMessageStatus.pending,
      );
      await repository.append(pending);

      await repository.append(pending.copyWith(status: AiMessageStatus.sent));

      final messages = (await repository.watchMessages('conv-1').first)
          .getRight()
          .toNullable()!;
      expect(messages, hasLength(1));
      expect(messages.single.status, AiMessageStatus.sent);
    });
  });

  group('updateProposalStatus', () {
    test('advances one card and leaves its siblings alone', () async {
      await repository.append(
        buildAiMessage(
          id: 'm1',
          proposals: [
            buildBudgetProposal(id: 'tc_0_0'),
            buildGoalProposal(id: 'tc_0_1'),
          ],
        ),
      );

      final result = await repository.updateProposalStatus(
        messageId: 'm1',
        proposalId: 'tc_0_0',
        status: AiProposalStatus.confirmed,
      );

      expect(result.isRight(), isTrue);
      final messages = (await repository.watchMessages('conv-1').first)
          .getRight()
          .toNullable()!;
      final proposals = messages.single.proposals;
      expect(proposals.first.status, AiProposalStatus.confirmed);
      expect(proposals.last.status, AiProposalStatus.pending);
    });

    test('a confirmed card survives a reopen, so it cannot be confirmed twice',
        () async {
      await repository.append(
        buildAiMessage(id: 'm1', proposals: [buildBudgetProposal()]),
      );
      await repository.updateProposalStatus(
        messageId: 'm1',
        proposalId: 'tc_0_0',
        status: AiProposalStatus.confirmed,
      );

      final reopened = AiHistoryRepositoryImpl(
        AiHistoryLocalDatasource(database),
        crash,
      );
      final messages = (await reopened.watchMessages('conv-1').first)
          .getRight()
          .toNullable()!;

      expect(messages.single.proposals.single.status,
          AiProposalStatus.confirmed);
    });

    test('an unknown message id is a NotFoundFailure, not a silent no-op',
        () async {
      final result = await repository.updateProposalStatus(
        messageId: 'nope',
        proposalId: 'tc_0_0',
        status: AiProposalStatus.confirmed,
      );

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test('an unknown proposal id on a real message is a NotFoundFailure',
        () async {
      await repository.append(
        buildAiMessage(id: 'm1', proposals: [buildBudgetProposal()]),
      );

      final result = await repository.updateProposalStatus(
        messageId: 'm1',
        proposalId: 'tc_9_9',
        status: AiProposalStatus.dismissed,
      );

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test('an unsupported card can still be dismissed', () async {
      await repository.append(
        buildAiMessage(
          id: 'm1',
          proposals: [buildUnsupportedProposal(id: 'tc_0_4')],
        ),
      );

      await repository.updateProposalStatus(
        messageId: 'm1',
        proposalId: 'tc_0_4',
        status: AiProposalStatus.dismissed,
      );

      final messages = (await repository.watchMessages('conv-1').first)
          .getRight()
          .toNullable()!;
      expect(
        messages.single.proposals.single,
        isA<UnsupportedProposal>()
            .having((p) => p.status, 'status', AiProposalStatus.dismissed),
      );
    });
  });

  group('resumeOrCreateConversation', () {
    test('returns a fresh UUID when nothing was ever said on this device',
        () async {
      final id = (await repository.resumeOrCreateConversation())
          .getRight()
          .toNullable()!;

      expect(id, hasLength(36));
      expect(int.tryParse(id), isNull);
    });

    test('does not persist the brand-new conversation it just made up',
        () async {
      final first = (await repository.resumeOrCreateConversation())
          .getRight()
          .toNullable()!;

      final second = (await repository.resumeOrCreateConversation())
          .getRight()
          .toNullable()!;

      expect(second, isNot(first));
    });

    test('resumes the last thread once it has messages', () async {
      await repository.append(
        buildAiMessage(id: 'm1', conversationId: 'conv-7'),
      );

      final id = (await repository.resumeOrCreateConversation())
          .getRight()
          .toNullable()!;

      expect(id, 'conv-7');
    });
  });

  group('clear', () {
    test('erases the thread the user asked to erase, and only that one',
        () async {
      await repository.append(buildAiMessage(id: 'm1'));
      await repository.append(
        buildAiMessage(id: 'm2', conversationId: 'conv-2'),
      );

      await repository.clear('conv-1');

      expect(
        (await repository.watchMessages('conv-1').first)
            .getRight()
            .toNullable(),
        isEmpty,
      );
      expect(
        (await repository.watchMessages('conv-2').first)
            .getRight()
            .toNullable(),
        hasLength(1),
      );
    });
  });

  group('privacy', () {
    late MockAiHistoryLocalDatasource local;
    late AiHistoryRepositoryImpl guarded;

    setUp(() {
      local = MockAiHistoryLocalDatasource();
      guarded = AiHistoryRepositoryImpl(local, crash);
    });

    test('a failing write reports the exception type, never the SQL that '
        'carries the message text', () async {
      when(() => local.findById(any())).thenThrow(const FakeDriftException());

      final result = await guarded.updateProposalStatus(
        messageId: 'm1',
        proposalId: 'tc_0_0',
        status: AiProposalStatus.confirmed,
      );

      final failure = result.getLeft().toNullable()!;
      expect(failure, isA<DatabaseFailure>());
      expect(failure.cause.toString(), isNot(contains('el bar')));
      expect(failure.cause.toString(), contains('FakeDriftException'));
      expect(failure.message, isNot(contains('el bar')));
      expect(crash.errors.single.toString(), isNot(contains('el bar')));
    });

    test('a failing stream is sanitised the same way before it is reported',
        () async {
      when(() => local.watchMessages(any())).thenAnswer(
        (_) => Stream<List<Never>>.error(const FakeDriftException()),
      );

      final result = await guarded.watchMessages('conv-1').first;

      final failure = result.getLeft().toNullable()!;
      expect(failure, isA<DatabaseFailure>());
      expect(failure.cause.toString(), isNot(contains('el bar')));
      expect(crash.errors.single.toString(), isNot(contains('el bar')));
    });

    test('nothing that reaches the crash reporter names a conversation',
        () async {
      when(() => local.deleteConversation(any()))
          .thenThrow(const FakeDriftException());

      await guarded.clear('conv-secret-1234');

      expect(
        crash.errors.single.toString(),
        isNot(contains('conv-secret-1234')),
      );
    });
  });
}
