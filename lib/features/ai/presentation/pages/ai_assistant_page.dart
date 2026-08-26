import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ai_message.dart';
import '../cubit/ai_chat_cubit.dart';
import '../cubit/ai_chat_state.dart';
import '../cubit/ai_consent_cubit.dart';
import '../cubit/ai_consent_state.dart';
import '../widgets/ai_assistant_bubble.dart';
import '../widgets/ai_beta_strip.dart';
import '../widgets/ai_chat_header.dart';
import '../widgets/ai_composer.dart';
import '../widgets/ai_empty_state.dart';
import '../widgets/ai_error_bubble.dart';
import '../widgets/ai_thinking_bubble.dart';
import '../widgets/ai_user_bubble.dart';
import 'ai_consent_page.dart';
import 'ai_signed_out_page.dart';

/// The assistant's chat screen (`billetudo.pen` `ueaIi`/`M2oLsq`/`V7gvu`/
/// `hAZza`): header, fixed legal strip, scrollable conversation, composer.
///
/// Gated twice, in order:
/// 1. [AiConsentCubit]: until `AppSettings.aiConsentAcceptedAt` is set, this
///    renders [AiConsentPage] instead of the chat entirely (Apple 5.1.2(i)).
/// 2. `AiChatState.isSignedIn`: the Edge Function behind every turn requires
///    a JWT, so without a session this renders [AiSignedOutPage] instead of
///    the composer — `AiChatCubit.start()` only runs once both gates are
///    clear, so the composer never becomes reachable before that.
class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({
    required this.onBack,
    required this.onOpenHistory,
    required this.onSignIn,
    super.key,
  });

  final VoidCallback onBack;

  /// Pushes the history list and returns the id of the conversation the user
  /// picked to reopen, or `null` on a plain back.
  final Future<String?> Function() onOpenHistory;

  /// Pushes the login flow ([AiSignedOutPage]'s CTA).
  final VoidCallback onSignIn;

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final ScrollController _scrollController = ScrollController();
  bool _chatStarted = false;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<AiConsentCubit>().start());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Starts the thread once both gates are clear (consent granted, session
  /// active). Called from two listeners — consent turning granted, and the
  /// session turning signed-in — since either can be the last one to clear.
  void _startChatOnce() {
    if (_chatStarted) {
      return;
    }
    if (context.read<AiConsentCubit>().state.status !=
        AiConsentStatus.granted) {
      return;
    }
    if (!context.read<AiChatCubit>().state.isSignedIn) {
      return;
    }
    _chatStarted = true;
    unawaited(context.read<AiChatCubit>().start());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _openHistory() async {
    final conversationId = await widget.onOpenHistory();
    if (conversationId != null && mounted) {
      await context.read<AiChatCubit>().start(conversationId: conversationId);
    }
  }

  Future<void> _newConversation() => context.read<AiChatCubit>().startNew();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiConsentCubit, AiConsentState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AiConsentStatus.granted,
      listener: (context, state) => _startChatOnce(),
      builder: (context, consentState) {
        if (consentState.status != AiConsentStatus.granted) {
          return AiConsentPage(onDecline: widget.onBack);
        }
        return BlocConsumer<AiChatCubit, AiChatState>(
          listenWhen: (previous, current) =>
              previous.isSignedIn != current.isSignedIn ||
              previous.messages.length != current.messages.length,
          listener: (context, state) {
            if (state.isSignedIn) {
              _startChatOnce();
            }
            _scrollToBottom();
          },
          builder: (context, chatState) {
            if (!chatState.isSignedIn) {
              return AiSignedOutPage(
                onBack: widget.onBack,
                onSignIn: widget.onSignIn,
              );
            }
            return Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    AiChatHeader(
                      onBack: widget.onBack,
                      onOpenHistory: () => unawaited(_openHistory()),
                      onNewConversation: () => unawaited(_newConversation()),
                    ),
                    const AiBetaStrip(),
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        children: [
                          if (chatState.messages.isEmpty &&
                              chatState.status == AiChatStatus.ready)
                            const AiEmptyState(),
                          for (final message in chatState.messages) ...[
                            message.role == AiMessageRole.user
                                ? AiUserBubble(message: message)
                                : AiAssistantBubble(
                                    message: message,
                                    accountNames: chatState.accountNames,
                                  ),
                            const SizedBox(height: 14),
                          ],
                          if (chatState.status == AiChatStatus.thinking)
                            const AiThinkingBubble(),
                          if (chatState.status == AiChatStatus.error)
                            AiErrorBubble(
                              onRetry: () => unawaited(
                                context.read<AiChatCubit>().retry(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const AiComposer(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
