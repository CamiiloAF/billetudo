import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../debts/domain/entities/debts_summary.dart';
import '../../../debts/domain/usecases/watch_debts.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/usecases/watch_ai_messages.dart';
import 'ai_conversation_read_state.dart';

/// Reads one past thread without going through `AiConsentCubit` or
/// `AiChatCubit` at all — reading sends nothing to Google, so it is never
/// gated behind consent (`AiConsentPage`'s "Ver mis conversaciones
/// anteriores" link, when consent was withdrawn or never granted). There is
/// no `send`/`start`/`startNew` here on purpose: this cubit cannot write a
/// message, by construction, not just by omission from the UI.
@injectable
class AiConversationReadCubit extends Cubit<AiConversationReadState> {
  AiConversationReadCubit(
    this._watchAiMessages,
    this._watchAccounts,
    this._watchDebts,
  ) : super(const AiConversationReadState());

  final WatchAiMessages _watchAiMessages;
  final WatchAccounts _watchAccounts;
  final WatchDebts _watchDebts;

  StreamSubscription<Result<List<AiMessage>>>? _messagesSubscription;
  StreamSubscription<Result<List<AccountWithBalance>>>? _accountsSubscription;
  StreamSubscription<Result<DebtsSummary>>? _debtsSubscription;

  Future<void> start(String conversationId) async {
    await _messagesSubscription?.cancel();
    await _accountsSubscription?.cancel();
    await _debtsSubscription?.cancel();
    if (isClosed) {
      return;
    }
    emit(const AiConversationReadState());

    _messagesSubscription =
        _watchAiMessages(conversationId).listen(_onMessages);

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

    _debtsSubscription = _watchDebts().listen((result) {
      if (isClosed) {
        return;
      }
      result.fold((failure) {}, (summary) {
        emit(
          state.copyWith(
            debtNames: {
              for (final entry in summary.debts) entry.debt.id: entry.debt.name,
            },
          ),
        );
      });
    });
  }

  void _onMessages(Result<List<AiMessage>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: AiConversationReadStatus.failure,
          failure: failure,
        ),
        (messages) => state.copyWith(
          status: AiConversationReadStatus.ready,
          messages: messages,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    await _accountsSubscription?.cancel();
    await _debtsSubscription?.cancel();
    return super.close();
  }
}
