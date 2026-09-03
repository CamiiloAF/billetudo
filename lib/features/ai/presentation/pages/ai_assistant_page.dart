import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ai_message.dart';
import '../cubit/ai_chat_cubit.dart';
import '../cubit/ai_chat_state.dart';
import '../cubit/ai_consent_cubit.dart';
import '../cubit/ai_consent_state.dart';
import '../cubit/ai_history_cubit.dart';
import '../cubit/ai_history_state.dart';
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
///
/// Neither gate blocks *reading* an already-saved thread: `AiConsentPage`'s
/// "Ver mis conversaciones anteriores" link (only shown when at least one
/// exists) opens `AiConversationReadPage` via [onOpenReadOnlyConversation]
/// instead, which never touches [AiChatCubit] or [AiConsentCubit] — there is
/// no code path from there back into the composer without going through
/// [AiConsentCubit.accept] first.
class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({
    required this.onBack,
    required this.onOpenHistory,
    required this.onOpenReadOnlyConversation,
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

  /// Pushes `AiConversationReadPage` for [AiConsentPage]'s "Ver mis
  /// conversaciones anteriores" link — a conversation reopened while consent
  /// is not granted goes here, in read-only mode, instead of resuming
  /// `AiChatCubit` (which would need a JWT-backed turn this screen has no
  /// consent to send).
  final void Function(String conversationId) onOpenReadOnlyConversation;

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
    // Same gap, for scroll position: a resumed conversation (from history, or
    // a long-lived AiChatCubit that already has messages from earlier this
    // session) mounts with `chatState.messages` already non-empty, and
    // `BlocConsumer`'s `listener` only fires on a *transition* after this
    // widget subscribes — never for the state the cubit already held. Without
    // this, the chat opened at the top instead of the latest message, exactly
    // backwards for something that reads bottom-to-top. Harmless no-op when
    // there are no messages yet (`maxScrollExtent` is 0).
    _scrollToBottom();
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
  ///
  /// Every branch below scrolls to the bottom itself once its `start`/`send`
  /// resolves, instead of leaning on the `BlocConsumer` listener's
  /// `messages.length` comparison (bug reported live, intermittent by
  /// nature: it only surfaces when the conversation being loaded here
  /// happens to have the exact same message count as whatever the
  /// long-lived `AiChatCubit` held before — reported live as "a veces se
  /// abre al inicio", intermittent because the coincidence is, not a
  /// consistent failure. `_openHistory` already learned this lesson; these
  /// three call sites hadn't.
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
        context
            .read<AiChatCubit>()
            .start(conversationId: conversationId)
            .then((_) {
          if (mounted) {
            _scrollToBottom();
          }
        }),
      );
      return;
    }
    final question = widget.initialQuestion;
    if (question != null && question.trim().isNotEmpty) {
      unawaited(_startWithQuestion(question));
      return;
    }
    unawaited(
      context.read<AiChatCubit>().start().then((_) {
        if (mounted) {
          _scrollToBottom();
        }
      }),
    );
  }

  Future<void> _startWithQuestion(String question) async {
    final cubit = context.read<AiChatCubit>();
    await cubit.startNew(insightType: widget.initialInsightType);
    if (!mounted || cubit.isClosed) {
      return;
    }
    // `startNew` resolves as soon as it *subscribes* to the new
    // conversation's message stream — not once that stream's first event
    // (even an empty list, for a brand-new thread) actually arrives.
    // `AiChatState` defaults to `AiChatStatus.loading` (`ai_chat_state.dart`)
    // and `canSend` refuses while loading, so calling `send()` right here
    // lost this race every time: the composer's draft got set, `send()`
    // silently no-op'd against `canSend == false`, and nothing was ever
    // sent — reported live as "abre el chat, pero no autoenvía el mensaje".
    // Waiting for the first non-loading state (already true almost
    // instantly in practice) closes that gap.
    if (cubit.state.status == AiChatStatus.loading) {
      try {
        await cubit.stream.firstWhere(
          (state) => state.status != AiChatStatus.loading,
        );
        // ignore: avoid_catching_errors
      } on StateError {
        // The cubit is injected, not owned by this widget (fresh per route
        // push, but disposed by its own `BlocProvider`) — if something
        // closes it before it ever leaves `loading` (e.g. a sign-out racing
        // this navigation), its stream closes with no matching event and
        // `firstWhere` throws instead of hanging. Nothing left to send to.
        return;
      }
    }
    if (!mounted || cubit.isClosed) {
      return;
    }
    cubit.updateDraft(question);
    await cubit.send();
    if (mounted) {
      _scrollToBottom();
    }
  }

  /// With the list's `reverse: true` (see the `Expanded` child's build-time
  /// comment), item 0 — the newest message — sits at the visual bottom when
  /// the scroll offset is 0, not at `maxScrollExtent`: reversing flips which
  /// end of the scrollable "the latest message" anchors to.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      }
    });
  }

  Future<void> _openHistory() async {
    final conversationId = await widget.onOpenHistory();
    if (conversationId != null && mounted) {
      await context.read<AiChatCubit>().start(conversationId: conversationId);
      // The `listenWhen` below only fires `_scrollToBottom` on a
      // `messages.length` change — but switching to a DIFFERENT conversation
      // from history can land on one with the exact same message count as
      // the one just left, so the listener never fires. The scroll
      // controller's pixel offset then carries over unchanged into content of
      // a different height, which can visually land anywhere, not
      // necessarily the top or bottom (bug reported live: it looked "stuck
      // at the top" of the newly-opened, taller conversation). Every switch
      // via history is a fresh "just opened this conversation" moment, same
      // as `initState`'s — call it explicitly instead of trusting the length
      // comparison to happen to catch it.
      if (mounted) {
        _scrollToBottom();
      }
    }
  }

  Future<void> _newConversation() => context.read<AiChatCubit>().startNew();

  /// [AiConsentPage]'s "Ver mis conversaciones anteriores" link: opens the
  /// same history list, but a picked conversation goes to the read-only
  /// screen instead of `AiChatCubit.start` — consent is not granted on this
  /// path, so resuming the real chat is not an option.
  Future<void> _openHistoryReadOnly() async {
    final conversationId = await widget.onOpenHistory();
    if (conversationId != null && mounted) {
      widget.onOpenReadOnlyConversation(conversationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiConsentCubit, AiConsentState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AiConsentStatus.granted,
      listener: (context, state) => _startChatOnce(),
      builder: (context, consentState) {
        if (consentState.status != AiConsentStatus.granted) {
          return BlocBuilder<AiHistoryCubit, AiHistoryState>(
            builder: (context, historyState) => AiConsentPage(
              onDecline: widget.onBack,
              hasHistory: !historyState.isEmpty,
              onOpenHistory: () => unawaited(_openHistoryReadOnly()),
            ),
          );
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
                      child: chatState.messages.isEmpty &&
                              chatState.status == AiChatStatus.ready
                          // Plain, scrollable `ListView` (not `Center`):
                          // `AiEmptyState`'s own content (orb + title +
                          // subtitle + 4 suggestion chips) can be taller
                          // than the viewport on a short screen or with the
                          // keyboard up, and `Center` has no fallback for
                          // that — it hard-overflows instead of scrolling
                          // (caught by a widget test using a deliberately
                          // short viewport). This branch was never part of
                          // the reported bug (only a short *conversation*
                          // left a gap — the empty state has no messages to
                          // anchor at all), so it keeps its original,
                          // already-safe top-aligned/scrollable behaviour.
                          ? ListView(children: const [AiEmptyState()])
                          // `billetudo.pen` `ueaIi`'s own note: "la
                          // conversacion se ancla abajo (justifyContent
                          // end): lo ultimo dicho queda pegado al
                          // composer" — a plain top-down `ListView` always
                          // lays its children out from the TOP, so a short
                          // thread (content shorter than the viewport) left
                          // a growing gap BELOW the last bubble instead,
                          // exactly backwards from the design (reported
                          // live: "queda un pedacito al final que no hace
                          // scroll" — confirmed by scrolling up and letting
                          // go: it settled back in the same place, so
                          // nothing was hidden below; the gap was real,
                          // structural dead space, not a missed scroll). A
                          // `reverse: true` list (the standard chat-UI
                          // idiom — WhatsApp/Telegram-style) fixes this at
                          // the root: item 0 anchors to the bottom edge
                          // regardless of how much content there is, so a
                          // short thread's leftover space lands above the
                          // first message instead. Building the widgets in
                          // the normal top-to-bottom order and reversing
                          // the finished list keeps every spacer between
                          // the right two bubbles without rewriting the
                          // spacing logic. (An earlier attempt forced a
                          // bottom-aligned `Column` via `IntrinsicHeight`
                          // inside a `SingleChildScrollView` instead —
                          // reverted: `IntrinsicHeight`'s dry layout pass
                          // doesn't match a `Row`-with-`Expanded`-text
                          // bubble's real layout, and produced a genuine
                          // overflow, caught by the widget tests before it
                          // ever reached a device.)
                          : ListView(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              children: [
                                for (final message in chatState.messages) ...[
                                  message.role == AiMessageRole.user
                                      ? AiUserBubble(message: message)
                                      : AiAssistantBubble(
                                          message: message,
                                          accountNames: chatState.accountNames,
                                          debtNames: chatState.debtNames,
                                          conversationId:
                                              chatState.conversationId,
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
                              ].reversed.toList(),
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
