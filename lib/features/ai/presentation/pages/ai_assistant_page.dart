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
import '../widgets/ai_error_bubble.dart';
import '../widgets/ai_thinking_bubble.dart';
import '../widgets/ai_user_bubble.dart';
import 'ai_consent_page.dart';

/// The assistant's chat screen (`billetudo.pen` `ueaIi`/`M2oLsq`/`V7gvu`/
/// `hAZza`): header, fixed legal strip, scrollable conversation, composer.
///
/// Gated by [AiConsentCubit]: until `AppSettings.aiConsentAcceptedAt` is set,
/// this renders [AiConsentPage] instead of the chat entirely (Apple
/// 5.1.2(i)) — `AiChatCubit.start()` only runs once the gate reports
/// [AiConsentStatus.granted], so the composer never becomes reachable before
/// that.
class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({
    required this.onBack,
    required this.onOpenHistory,
    super.key,
  });

  final VoidCallback onBack;

  /// Pushes the history list and returns the id of the conversation the user
  /// picked to reopen, or `null` on a plain back.
  final Future<String?> Function() onOpenHistory;

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

  void _startChatOnce() {
    if (_chatStarted) {
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

  Future<void> _newConversation() => context.read<AiChatCubit>().start();

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
                  child: BlocConsumer<AiChatCubit, AiChatState>(
                    listenWhen: (previous, current) =>
                        previous.messages.length != current.messages.length,
                    listener: (context, state) => _scrollToBottom(),
                    builder: (context, state) => ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      children: [
                        for (final message in state.messages) ...[
                          message.role == AiMessageRole.user
                              ? AiUserBubble(message: message)
                              : AiAssistantBubble(
                                  message: message,
                                  accountNames: state.accountNames,
                                ),
                          const SizedBox(height: 14),
                        ],
                        if (state.status == AiChatStatus.thinking)
                          const AiThinkingBubble(),
                        if (state.status == AiChatStatus.error)
                          AiErrorBubble(
                            onRetry: () => unawaited(
                              context.read<AiChatCubit>().retry(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const AiComposer(),
              ],
            ),
          ),
        );
      },
    );
  }
}
