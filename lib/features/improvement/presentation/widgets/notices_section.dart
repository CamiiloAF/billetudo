import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/insight.dart';
import '../cubit/insights_cubit.dart';
import '../cubit/insights_state.dart';
import 'insight_notice_card.dart';

/// The "Avisos" section of the notice centre (`dtGcP` in `Bk8zW`, `owTOv` in
/// `Z38Eox`): the list of locally-derived notices, 10pt apart.
///
/// **Deliberately headerless.** It is the first section of a screen already
/// titled "Avisos", and repeating the title under itself informs nobody
/// (frame decision, 2026-09-09).
///
/// **Renders nothing when there is nothing.** Composition rule of the screen:
/// a section only exists if it has content — no orphan header, no local empty
/// state. The full-screen "Todo al día" belongs to the page, which owns the
/// knowledge that *every* section is empty; this widget only knows about its
/// own.
class NoticesSection extends StatelessWidget {
  const NoticesSection({
    required this.onOpenInsight,
    super.key,
  });

  /// Navigates to what the notice is about. The page owns routing: the
  /// template detail for a charge or a pending occurrence, the goal detail
  /// for a milestone (see [Insight.targetId] and [Insight.type]).
  final ValueChanged<Insight> onOpenInsight;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InsightsCubit, InsightsState>(
      builder: (context, state) {
        if (state.insights.isEmpty) {
          return const SizedBox.shrink();
        }
        final cubit = context.read<InsightsCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < state.insights.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              InsightNoticeCard(
                insight: state.insights[i],
                onOpen: onOpenInsight,
                onDismiss: cubit.dismiss,
              ),
            ],
          ],
        );
      },
    );
  }
}
