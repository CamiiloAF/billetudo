import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/ai_client_context.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/usecases/watch_auth_session.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/entities/ai_tool_call.dart';
import '../../domain/entities/ai_turn.dart';
import '../../domain/usecases/append_ai_message.dart';
import '../../domain/usecases/build_financial_snapshot.dart';
import '../../domain/usecases/link_insight_to_conversation.dart';
import '../../domain/usecases/resolve_ai_tool_call.dart';
import '../../domain/usecases/resume_or_create_ai_conversation.dart';
import '../../domain/usecases/send_ai_turn.dart';
import '../../domain/usecases/start_new_ai_conversation.dart';
import '../../domain/usecases/watch_ai_messages.dart';
import 'ai_chat_state.dart';

const _uuid = Uuid();

/// Drives one chat thread: resumes/creates it, streams its messages, and
/// sends turns.
///
/// The tool-resolution loop is capped at one extra round: the backend
/// contract only ever asks for reads once before answering
/// (`supabase/functions/README.md`), so a second `needsToolResolution` on the
/// follow-up response is shown as-is rather than chased again.
@injectable
class AiChatCubit extends Cubit<AiChatState> {
  AiChatCubit(
    this._resumeOrCreateAiConversation,
    this._startNewAiConversation,
    this._watchAiMessages,
    this._appendAiMessage,
    this._buildFinancialSnapshot,
    this._sendAiTurn,
    this._resolveAiToolCall,
    this._watchAccounts,
    this._clientContext,
    this._linkInsightToConversation,
    WatchAuthSession watchAuthSession,
  ) : super(AiChatState(isSignedIn: watchAuthSession.current.isSignedIn)) {
    _authSubscription = watchAuthSession().listen(_onAuthSession);
  }

  final ResumeOrCreateAiConversation _resumeOrCreateAiConversation;
  final StartNewAiConversation _startNewAiConversation;
  final WatchAiMessages _watchAiMessages;
  final AppendAiMessage _appendAiMessage;
  final BuildFinancialSnapshot _buildFinancialSnapshot;
  final SendAiTurn _sendAiTurn;
  final ResolveAiToolCall _resolveAiToolCall;
  final WatchAccounts _watchAccounts;
  final AiClientContextProvider _clientContext;
  final LinkInsightToConversation _linkInsightToConversation;

  StreamSubscription<Result<List<AiMessage>>>? _messagesSubscription;
  StreamSubscription<Result<List<AccountWithBalance>>>? _accountsSubscription;
  StreamSubscription<AuthSession>? _authSubscription;

  void _onAuthSession(AuthSession session) {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(isSignedIn: session.isSignedIn));
  }

  /// Opens a thread. [conversationId] reopens that exact thread (tapping a
  /// `Conversation Row` in the history list); `null` (app-launch/AI Banner
  /// entry) resumes the last thread or creates a fresh one, matching
  /// `AiHistoryRepository.resumeOrCreateConversation`'s own contract.
  ///
  /// No-op without a session: the Edge Function behind every turn requires a
  /// JWT, and `AiAssistantPage` never calls this before
  /// [AiChatState.isSignedIn] is `true` — this guard only covers a stale
  /// call racing a sign-out.
  Future<void> start({String? conversationId}) async {
    if (!state.isSignedIn) {
      return;
    }
    await _messagesSubscription?.cancel();
    await _accountsSubscription?.cancel();
    if (isClosed) {
      return;
    }
    emit(AiChatState(isSignedIn: state.isSignedIn));

    _accountsSubscription = _watchAccounts().listen((result) {
      if (isClosed) {
        return;
      }
      result.fold((failure) {}, (accounts) {
        emit(
          state.copyWith(
            accountNames: {
              for (final entry in accounts)
                entry.account.id: entry.account.name,
            },
          ),
        );
      });
    });

    if (conversationId != null) {
      emit(state.copyWith(conversationId: conversationId));
      _messagesSubscription =
          _watchAiMessages(conversationId).listen(_onMessages);
      return;
    }

    final result = await _resumeOrCreateAiConversation();
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(status: AiChatStatus.error, failure: failure),
      ),
      (resumedId) {
        emit(state.copyWith(conversationId: resumedId));
        _messagesSubscription = _watchAiMessages(resumedId).listen(_onMessages);
      },
    );
  }

  /// Forces a brand-new thread (the header's "+" button, or Home's AI card
  /// insight chip) instead of resuming the last one — unlike [start], which
  /// `_resumeOrCreateAiConversation` deliberately reuses.
  ///
  /// [insightType] (`HomeAiInsightType.name`), when set, is the AI card
  /// insight this thread was started from — the moment the new id exists it
  /// is linked to it (`LinkInsightToConversation`), so that chip flips to
  /// "continuar conversación" on return (bugfix item 7). `null` for the
  /// header's own "+" button, which is not tied to any insight.
  Future<void> startNew({String? insightType}) async {
    if (!state.isSignedIn) {
      return;
    }
    final result = await _startNewAiConversation();
    if (isClosed) {
      return;
    }
    await result.fold(
      (failure) async => emit(
        state.copyWith(status: AiChatStatus.error, failure: failure),
      ),
      (newConversationId) async {
        await start(conversationId: newConversationId);
        if (insightType != null) {
          await _linkInsightToConversation(
            insightType: insightType,
            conversationId: newConversationId,
          );
        }
      },
    );
  }

  void _onMessages(Result<List<AiMessage>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) =>
            state.copyWith(status: AiChatStatus.error, failure: failure),
        (messages) => state.copyWith(
          // A `thinking`/`error` turn in flight owns the status; a plain
          // history update while idle settles into `ready`.
          status: state.status == AiChatStatus.thinking
              ? AiChatStatus.thinking
              : AiChatStatus.ready,
          messages: messages,
        ),
      ),
    );
  }

  void updateDraft(String value) => emit(state.copyWith(draft: value));

  /// Sends the composer's current draft as a new user bubble.
  Future<void> send() async {
    final text = state.draft.trim();
    final conversationId = state.conversationId;
    if (text.isEmpty || conversationId == null || !state.canSend) {
      return;
    }

    final userMessage = AiMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: AiMessageRole.user,
      content: text,
      createdAt: clock.now(),
      status: AiMessageStatus.pending,
    );
    // Captured before the pending bubble necessarily reaches `state.messages`
    // through the stream, so the wire request always carries it.
    final history = [...state.messages, userMessage];

    emit(
      state.copyWith(
        draft: '',
        status: AiChatStatus.thinking,
        clearFailure: true,
      ),
    );
    await _appendAiMessage(userMessage);
    if (isClosed) {
      return;
    }
    await _runTurn(
      conversationId: conversationId,
      history: history,
      userMessage: userMessage,
    );
  }

  /// Retries the last user message after a failed turn (the error bubble's
  /// "Reintentar" link) — no new bubble, just another attempt.
  Future<void> retry() async {
    final conversationId = state.conversationId;
    if (conversationId == null || state.status == AiChatStatus.thinking) {
      return;
    }
    AiMessage? lastUser;
    for (final message in state.messages.reversed) {
      if (message.role == AiMessageRole.user) {
        lastUser = message;
        break;
      }
    }
    if (lastUser == null) {
      return;
    }

    emit(state.copyWith(status: AiChatStatus.thinking, clearFailure: true));
    await _runTurn(
      conversationId: conversationId,
      history: state.messages,
      userMessage: lastUser,
    );
  }

  Future<void> _runTurn({
    required String conversationId,
    required List<AiMessage> history,
    required AiMessage userMessage,
  }) async {
    // Wire cap (`AiTurnRequest.maxMessages`): trimmed proactively on every
    // turn rather than only after a `413 payload_too_large`, which is what
    // the documented "prune and resend" handling amounts to when applied
    // ahead of time.
    final trimmed = history.length > AiTurnRequest.maxMessages
        ? history.sublist(history.length - AiTurnRequest.maxMessages)
        : history;

    final outcome = await _attemptTurn(conversationId, trimmed);
    if (isClosed) {
      return;
    }

    if (outcome case Left(value: final failure)) {
      await _appendAiMessage(
        userMessage.copyWith(status: AiMessageStatus.failed),
      );
      if (!isClosed) {
        emit(state.copyWith(status: AiChatStatus.error, failure: failure));
      }
      return;
    }

    await _appendAiMessage(userMessage.copyWith(status: AiMessageStatus.sent));
    if (!isClosed) {
      emit(state.copyWith(status: AiChatStatus.ready));
    }
  }

  FutureResult<Unit> _attemptTurn(
    String conversationId,
    List<AiMessage> history,
  ) async {
    final snapshotResult = await _buildFinancialSnapshot();
    final snapshot = snapshotResult.fold((_) => null, (value) => value);
    final context = await _clientContext.resolve();

    final firstResult = await _sendAiTurn(
      AiTurnRequest(
        conversationId: conversationId,
        locale: context.locale,
        timezone: context.timezone,
        clientVersion: context.clientVersion,
        messages: history,
        snapshot: snapshot,
      ),
    );

    final AiTurnResponse firstResponse;
    switch (firstResult) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final response):
        firstResponse = response;
    }

    if (!firstResponse.needsToolResolution) {
      return _persistAssistantReply(conversationId, firstResponse);
    }

    final toolResults = <AiToolResult>[];
    for (final call in firstResponse.toolCalls) {
      final resolved = await _resolveAiToolCall(call);
      if (resolved case Right(value: final toolResult)) {
        toolResults.add(toolResult);
      }
    }

    final secondResult = await _sendAiTurn(
      AiTurnRequest(
        conversationId: conversationId,
        locale: context.locale,
        timezone: context.timezone,
        clientVersion: context.clientVersion,
        messages: history,
        snapshot: snapshot,
        toolResults: toolResults,
      ),
    );
    switch (secondResult) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final response):
        return _persistAssistantReply(conversationId, response);
    }
  }

  FutureResult<Unit> _persistAssistantReply(
    String conversationId,
    AiTurnResponse response,
  ) =>
      _appendAiMessage(
        AiMessage(
          id: _uuid.v4(),
          conversationId: conversationId,
          role: AiMessageRole.assistant,
          content: response.content,
          createdAt: clock.now(),
          status: AiMessageStatus.sent,
          proposals: response.proposals,
        ),
      );

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    await _accountsSubscription?.cancel();
    await _authSubscription?.cancel();
    return super.close();
  }
}
