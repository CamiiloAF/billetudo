import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The 1px `$border` line between two `AiProposalDetailRow`s
/// (`billetudo.pen` `wb40J`/`VGMlD`).
class AiProposalDivider extends StatelessWidget {
  const AiProposalDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: context.colors.border);
}
