import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../cubit/ai_history_cubit.dart';
import '../cubit/ai_history_state.dart';
import '../widgets/conversation_row.dart';
import '../widgets/conversation_skeleton_row.dart';
import '../widgets/sheets/confirm_delete_all_conversations_sheet.dart';
import '../widgets/sheets/confirm_delete_conversation_sheet.dart';

/// The history list (`billetudo.pen` `EGwSs`/`Si9o8`/`bDdyA`/`JZVFV`).
///
/// Pops with the id of the conversation the user picked to reopen — either
/// by tapping a row or by "Nueva conversación" from the empty state — so the
/// chat screen that pushed this route can resume `AiChatCubit` on it. Pops
/// with `null` on a plain back.
class AiHistoryPage extends StatelessWidget {
  const AiHistoryPage({super.key});

  static const int _skeletonRowCount = 5;

  Future<void> _deleteOne(BuildContext context, String conversationId) async {
    final confirmed = await ConfirmDeleteConversationSheet.show(context);
    if ((confirmed ?? false) && context.mounted) {
      await context.read<AiHistoryCubit>().deleteConversation(conversationId);
    }
  }

  Future<void> _deleteAll(BuildContext context) async {
    final confirmed = await ConfirmDeleteAllConversationsSheet.show(context);
    if ((confirmed ?? false) && context.mounted) {
      await context.read<AiHistoryCubit>().deleteAll();
    }
  }

  Future<void> _startNew(BuildContext context) async {
    final cubit = context.read<AiHistoryCubit>();
    final id = await cubit.startNewConversation();
    if (id != null && context.mounted) {
      Navigator.of(context).pop(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<AiHistoryCubit, AiHistoryState>(
              buildWhen: (previous, current) =>
                  previous.isEmpty != current.isEmpty,
              builder: (context, state) => PageHeader(
                title: l10n.aiHistoryTitle,
                trailing: state.isEmpty
                    ? null
                    : PageHeaderCircleButton(
                        icon: LucideIcons.trash2,
                        background: colors.muted,
                        foreground: colors.expenseText,
                        tooltip: l10n.aiHistoryDeleteAllTooltip,
                        onPressed: () => unawaited(_deleteAll(context)),
                      ),
              ),
            ),
            Expanded(
              child: BlocBuilder<AiHistoryCubit, AiHistoryState>(
                builder: (context, state) => switch (state.status) {
                  AiHistoryStatus.loading => ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                      itemCount: _skeletonRowCount,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) =>
                          const ConversationSkeletonRow(),
                    ),
                  AiHistoryStatus.failure => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ErrorState(
                          title: l10n.aiHistoryErrorTitle,
                          onRetry: () =>
                              unawaited(context.read<AiHistoryCubit>().start()),
                        ),
                      ),
                    ),
                  AiHistoryStatus.ready when state.isEmpty => EmptyState(
                      icon: LucideIcons.sparkles,
                      message: l10n.aiHistoryEmptyMessage,
                      ctaLabel: l10n.aiHistoryEmptyCta,
                      onCta: () => unawaited(_startNew(context)),
                    ),
                  AiHistoryStatus.ready => ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                      itemCount: state.conversations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final conversation = state.conversations[index];
                        return ConversationRow(
                          conversation: conversation,
                          onTap: () =>
                              Navigator.of(context).pop(conversation.id),
                          onDelete: () =>
                              unawaited(_deleteOne(context, conversation.id)),
                        );
                      },
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
