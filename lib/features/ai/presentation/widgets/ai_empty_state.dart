import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/ai_chat_cubit.dart';
import 'ai_orb.dart';
import 'ai_suggestion_chip.dart';

/// Shown instead of a blank list when a thread has no messages yet — a fresh
/// conversation (the "+" button) or the first-ever open. Without this, an
/// empty `ListView` under the beta strip reads as broken, not as "nothing was
/// asked yet": there is nothing on screen to tell the two states apart.
///
/// Matches `billetudo.pen` `p3tJFm` (light) / `hx3IY` (dark): the 48px
/// [AiOrb] as the protagonist, a title/subtitle pair, and 4
/// [AiSuggestionChip]s stacked full-width, all centered vertically.
class AiEmptyState extends StatelessWidget {
  const AiEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AiChatCubit>();

    // Tapping a chip sends the suggestion right away instead of only
    // filling the composer's draft. It reuses `AiComposer._send`'s own path
    // (`updateDraft` then `send`, which reads the draft it just set) so a
    // chip behaves exactly like the user typing that question and hitting
    // Send.
    void selectSuggestion(String text) {
      cubit.updateDraft(text);
      unawaited(cubit.send());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const AiOrb(size: 48),
          const SizedBox(height: 20),
          Text(
            l10n.aiChatEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.aiChatEmptySubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          AiSuggestionChip(
            label: l10n.aiChatSuggestionMonthProgress,
            onTap: () => selectSuggestion(l10n.aiChatSuggestionMonthProgress),
          ),
          const SizedBox(height: 8),
          AiSuggestionChip(
            label: l10n.aiChatSuggestionBuildBudget,
            onTap: () => selectSuggestion(l10n.aiChatSuggestionBuildBudget),
          ),
          const SizedBox(height: 8),
          AiSuggestionChip(
            label: l10n.aiChatSuggestionGoalsSaved,
            onTap: () => selectSuggestion(l10n.aiChatSuggestionGoalsSaved),
          ),
          const SizedBox(height: 8),
          AiSuggestionChip(
            label: l10n.aiChatSuggestionBiggestSpend,
            onTap: () => selectSuggestion(l10n.aiChatSuggestionBiggestSpend),
          ),
        ],
      ),
    );
  }
}
