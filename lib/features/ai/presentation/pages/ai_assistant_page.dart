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
    this.initialQuestion,
    this.initialInsightType,
    this.initialConversationId,
    super.key,
  });

  final VoidCallback onBack;

  /// Pushes the history list and returns the id of the conversation the user
  /// picked to reopen, or `null` on a plain back.
  final Future<String?> Function() onOpenHistory;

  /// Pushes the login flow ([AiSignedOutPage]'s CTA).
  final VoidCallback onSignIn;

  /// A question pre-seeded from Home's AI card chips (Router's
  /// `initialQuestion` query param). When non-empty, the first start forces
  /// a brand-new thread (`AiChatCubit.startNew`) and sends it right away
  /// instead of resuming the last conversation.
  final String? initialQuestion;

  /// The Home AI card insight (`HomeAiInsightType.name`) that seeded
  /// [initialQuestion], when this launch came from that card's own
  /// "iniciar conversación" chip (bugfix item 7). Ignored without a
  /// [initialQuestion] — the brand-new thread `initialQuestion` forces is
  /// what gets linked to it, via `AiChatCubit.startNew`.
  final String? initialInsightType;

  /// A specific thread to reopen straight away — set by Home's AI card
  /// insight chip once it already has `HomeAiInsight.conversationId`
  /// (bugfix item 7), same navigation shape as picking a row from the
  /// history list (`_openHistory`). Takes priority over [initialQuestion]
  /// when both are somehow present.
  final String? initialConversationId;

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
    // Both cubits are long-lived singletons: on a SECOND visit this session,
    // consent may already read `granted` and the chat may already read
    // `isSignedIn: true` from the previous visit, so neither transitions —
    // the `BlocConsumer` listeners below only fire on a *change*, and would
    // silently never call `_startChatOnce()` at all. That was the bug: the
    // screen opened with an empty composer and never sent the seeded
    // question. This eager call closes that gap; it still no-ops via its own
    // two guards when a gate genuinely is not clear yet, and the listeners
    // remain the ones that fire once it does.
    _startChatOnce();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Starts the thread once both gates are clear (consent granted, session
  /// active). Called from two listeners — consent turning granted, and the
  /// session turning signed-in — since either can be the last one to clear.
  ///
  /// With a non-empty [AiAssistantPage.initialQuestion] (Home's AI card
  /// chips), this forces a brand-new thread and sends the question right
  /// away instead of resuming the last conversation.
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
    final conversationId = widget.initialConversationId;
    if (conversationId != null && conversationId.trim().isNotEmpty) {
      unawaited(
        context.read<AiChatCubit>().start(conversationId: conversationId),
      );
      return;
    }
    final question = widget.initialQuestion;
    if (question != null && question.trim().isNotEmpty) {
      unawaited(_startWithQuestion(question));
      return;
    }
    unawaited(context.read<AiChatCubit>().start());
  }

  Future<void> _startWithQuestion(String question) async {
    final cubit = context.read<AiChatCubit>();
    await cubit.startNew(insightType: widget.initialInsightType);
    if (!mounted) {
      return;
    }
    cubit.updateDraft(question);
    await cubit.send();
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
