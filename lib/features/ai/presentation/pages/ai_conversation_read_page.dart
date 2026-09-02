import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../domain/entities/ai_message.dart';
import '../cubit/ai_conversation_read_cubit.dart';
import '../cubit/ai_conversation_read_state.dart';
import '../widgets/ai_assistant_bubble.dart';
import '../widgets/ai_read_only_banner.dart';
import '../widgets/ai_user_bubble.dart';

/// Renders one past thread without a composer (`AiConsentPage`'s "Ver mis
/// conversaciones anteriores"): a user who withdrew AI consent — or never
/// granted it — can still read what is already on their device, since
/// reading sends nothing to Google. Sending a *new* message still requires
/// consent: this screen has no `AiConversationReadCubit.start`-adjacent send
/// path at all, by construction.
///
/// [conversationId] identifies the thread; [onReactivate] is the banner's
/// CTA back to `AiConsentPage` to grant consent again.
class AiConversationReadPage extends StatefulWidget {
  const AiConversationReadPage({
    required this.conversationId,
    required this.onBack,
    required this.onReactivate,
    super.key,
  });

  final String conversationId;
  final VoidCallback onBack;
  final VoidCallback onReactivate;

  @override
  State<AiConversationReadPage> createState() => _AiConversationReadPageState();
}

class _AiConversationReadPageState extends State<AiConversationReadPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(
      context.read<AiConversationReadCubit>().start(widget.conversationId),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Same fix as `AiAssistantPage._scrollToBottom`, and this screen needed it
  /// too — it never had a `ScrollController` at all before this: reported
  /// live, opening a past conversation from `AiConsentPage`'s "Ver mis
  /// conversaciones anteriores" landed at the top "como una pantalla
  /// normal", exactly backwards for something that reads bottom-to-top.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: l10n.aiConversationReadTitle,
              onBack: widget.onBack,
            ),
            AiReadOnlyBanner(onReactivate: widget.onReactivate),
            Expanded(
              child: BlocConsumer<AiConversationReadCubit,
                  AiConversationReadState>(
                listenWhen: (previous, current) =>
                    previous.status != current.status &&
                    current.status == AiConversationReadStatus.ready,
                listener: (context, state) => _scrollToBottom(),
                builder: (context, state) => switch (state.status) {
                  AiConversationReadStatus.loading => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  AiConversationReadStatus.failure => ErrorState(
                      title: l10n.aiConversationReadErrorTitle,
                      onRetry: () => unawaited(
                        context
                            .read<AiConversationReadCubit>()
                            .start(widget.conversationId),
                      ),
                    ),
                  AiConversationReadStatus.ready => ListView(
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
                                  debtNames: state.debtNames,
                                ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
