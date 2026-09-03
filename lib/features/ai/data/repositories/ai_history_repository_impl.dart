import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/result.dart';
import '../../domain/entities/ai_action_proposal.dart';
import '../../domain/entities/ai_conversation.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/repositories/ai_history_repository.dart';
import '../datasources/ai_history_local_datasource.dart';
import '../mappers/ai_message_mapper.dart';

const _uuid = Uuid();

/// Max length of a conversation title before it is truncated with an
/// ellipsis. Chosen to fit one line of a history-list row without wrapping.
const _titleMaxLength = 60;

/// Drift implementation of [AiHistoryRepository].
///
/// Same guard shape as the rest of the app's local repositories (see
/// `GoalQuickAmountsRepositoryImpl`) with one rule on top: **no chat content
/// ever reaches the crash reporter.** The context strings below name the
/// operation and nothing else — no message body, no proposal payload, not even
/// a conversation id. The privacy policy (§17.5) promises the transcript lives
/// on no server, and Sentry is a server.
@LazySingleton(as: AiHistoryRepository)
class AiHistoryRepositoryImpl implements AiHistoryRepository {
  const AiHistoryRepositoryImpl(this._local, this._crash);

  final AiHistoryLocalDatasource _local;
  final CrashReporter _crash;

  @override
  Stream<Result<List<AiMessage>>> watchMessages(String conversationId) =>
      _guardStream(
        _local.watchMessages(conversationId).map(
              (rows) => Right(rows.map(AiMessageMapper.toEntity).toList()),
            ),
      );

  @override
  FutureResult<Unit> append(AiMessage message) => _guard(() async {
        await _local.upsertMessage(AiMessageMapper.toCompanion(message));
        return const Right(unit);
      });

  @override
  FutureResult<Unit> updateProposalStatus({
    required String messageId,
    required String proposalId,
    required AiProposalStatus status,
  }) =>
      _guard(() async {
        final row = await _local.findById(messageId);
        if (row == null) {
          return const Left(
            NotFoundFailure('no ai message with that id to update'),
          );
        }

        final proposals = AiMessageMapper.decodeProposals(row.proposalsJson);
        if (!proposals.any((proposal) => proposal.id == proposalId)) {
          return const Left(
            NotFoundFailure('no proposal with that id on this ai message'),
          );
        }

        // Rebuilt through the mapper rather than patched as raw JSON: the card
        // that gets re-read after a relaunch is then exactly the one this
        // build can parse, instead of a document that only round-trips by
        // accident.
        final updated = <AiActionProposal>[
          for (final proposal in proposals)
            proposal.id == proposalId ? proposal.withStatus(status) : proposal,
        ];

        await _local.updateProposalsJson(
          id: messageId,
          proposalsJson: AiMessageMapper.encodeProposals(updated),
        );
        return const Right(unit);
      });

  @override
  FutureResult<String> resumeOrCreateConversation() => _guard(() async {
        final last = await _local.lastConversationId();
        // A brand-new id is not persisted here: there is no `ai_conversations`
        // table, so a conversation exists exactly as long as it has messages.
        // The first `append` is what makes it real, and a user who opens the
        // assistant without typing leaves nothing behind.
        return Right(last ?? _uuid.v4());
      });

  @override
  FutureResult<Unit> clear(String conversationId) => _guard(() async {
        await _local.deleteConversation(conversationId);
        return const Right(unit);
      });

  @override
  FutureResult<Unit> clearAll() => _guard(() async {
        await _local.deleteAll();
        return const Right(unit);
      });

  @override
  FutureResult<String> startNewConversation() async => Right(_uuid.v4());

  @override
  Stream<Result<List<AiConversation>>> watchConversations() => _guardStream(
        _local.watchConversationSummaries().asyncMap((summaries) async {
          // The count/last-message-at aggregate and the first-user-message
          // lookup are two separate queries (see the datasource doc), so they
          // are joined here rather than in SQL.
          final firstUserByConversation = <String, db.AiMessage>{};
          for (final message in await _local.firstUserMessages()) {
            firstUserByConversation[message.conversationId] = message;
          }

          final conversations = [
            for (final summary in summaries)
              AiConversation(
                id: summary.conversationId,
                title: _title(firstUserByConversation[summary.conversationId]),
                updatedAt: DateTime.fromMillisecondsSinceEpoch(
                  summary.lastMessageAt,
                ),
                messageCount: summary.messageCount,
              ),
          ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return Right(conversations);
        }),
      );

  /// Derives a thread's title from its first user message, truncated so a
  /// history-list row never wraps. `null` when the thread has no user
  /// message on record — see [AiConversation.title].
  String? _title(db.AiMessage? firstUserMessage) {
    final content = firstUserMessage?.content.trim();
    if (content == null || content.isEmpty) {
      return null;
    }
    if (content.length <= _titleMaxLength) {
      return content;
    }
    return '${content.substring(0, _titleMaxLength)}…';
  }

  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      await _crash.recordError(_sanitize(e), st, context: 'ai history query');
      return Left(
        DatabaseFailure(
          'ai history query failed',
          cause: _sanitize(e),
          stackTrace: st,
        ),
      );
    }
  }

  Stream<Result<T>> _guardStream<T>(Stream<Result<T>> source) =>
      source.transform(
        StreamTransformer<Result<T>, Result<T>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            unawaited(
              _crash.recordError(
                _sanitize(error),
                stackTrace,
                context: 'ai history stream',
              ),
            );
            sink.add(
              Left(
                DatabaseFailure(
                  'ai history stream stopped',
                  cause: _sanitize(error),
                  stackTrace: stackTrace,
                ),
              ),
            );
          },
        ),
      );

  /// Strips the original exception down to its type before it can reach the
  /// crash reporter.
  ///
  /// This is the one repository where attaching the real exception is unsafe:
  /// a failing Drift statement reports itself with the SQL — and, depending on
  /// the driver, the bound values — which for this table means the text of a
  /// message. `CrashReporter.recordFailure` uploads `Failure.cause` verbatim,
  /// so the sanitising has to happen here rather than at the reporting site.
  /// The stack trace still points at the exact query, which is what actually
  /// makes one of these debuggable.
  Object _sanitize(Object error) =>
      StateError('ai history failed with ${error.runtimeType}');
}
