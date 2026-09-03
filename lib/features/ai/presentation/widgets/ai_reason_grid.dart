import 'package:flutter/material.dart';

import '../../domain/entities/ai_report.dart';
import 'ai_reason_chip.dart';

/// The `Reason Grid` (`XUDJQ`/`K58dX`): the five motives in a 2-2-1 layout —
/// two full rows of two `AiReasonChip`s, then "Otro" alone at full width.
/// Single-select (radio semantics, not multi-select): picking one clears any
/// previous pick.
class AiReasonGrid extends StatelessWidget {
  const AiReasonGrid({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final AiReportReason? selected;
  final ValueChanged<AiReportReason> onSelected;

  static const List<AiReportReason> _pairedReasons = [
    AiReportReason.offensive,
    AiReportReason.wrong,
    AiReportReason.harmful,
    AiReportReason.privacy,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _pairedReasons.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AiReasonChip(
                  reason: _pairedReasons[i],
                  selected: selected == _pairedReasons[i],
                  onTap: () => onSelected(_pairedReasons[i]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AiReasonChip(
                  reason: _pairedReasons[i + 1],
                  selected: selected == _pairedReasons[i + 1],
                  onTap: () => onSelected(_pairedReasons[i + 1]),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        AiReasonChip(
          reason: AiReportReason.other,
          selected: selected == AiReportReason.other,
          onTap: () => onSelected(AiReportReason.other),
        ),
      ],
    );
  }
}
