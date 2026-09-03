import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/ai_conversation.dart';
import '../../domain/usecases/clear_ai_history.dart';
import '../../domain/usecases/clear_all_ai_history.dart';
import '../../domain/usecases/start_new_ai_conversation.dart';
import '../../domain/usecases/watch_ai_conversations.dart';
import 'ai_history_state.dart';

/// Drives the history list (`billetudo.pen` `EGwSs`): every thread with at
/// least one message, most recently updated first, plus "empezar de nuevo"
/// and the two delete flows.
@injectable
class AiHistoryCubit extends Cubit<AiHistoryState> {
  AiHistoryCubit(
    this._watchAiConversations,
    this._startNewAiConversation,
    this._clearAiHistory,
    this._clearAllAiHistory,
  ) : super(const AiHistoryState());

  final WatchAiConversations _watchAiConversations;
  final StartNewAiConversation _startNewAiConversation;
  final ClearAiHistory _clearAiHistory;
  final ClearAllAiHistory _clearAllAiHistory;

  StreamSubscription<Result<List<AiConversation>>>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    emit(const AiHistoryState());
    _subscription = _watchAiConversations().listen(_onConversations);
  }

  void _onConversations(Result<List<AiConversation>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: AiHistoryStatus.failure,
          failure: failure,
        ),
        (conversations) => state.copyWith(
          status: AiHistoryStatus.ready,
          conversations: conversations,
        ),
      ),
    );
  }

  /// Starts a brand-new thread and returns its id, so the caller can
  /// navigate the chat screen to it.
  Future<String?> startNewConversation() async {
    final result = await _startNewAiConversation();
    return result.fold((failure) => null, (id) => id);
  }

  Future<void> deleteConversation(String conversationId) =>
      _clearAiHistory(conversationId);

  Future<void> deleteAll() => _clearAllAiHistory();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
