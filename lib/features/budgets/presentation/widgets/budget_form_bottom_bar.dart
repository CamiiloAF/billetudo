import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The pinned CTA bar of the budget form (`a3gGPM/l1wrUJ`): `$surface` with a
/// 1pt top `$border` and padding `[12, 20, 20, 20]`, holding the primary
/// button at full width.
///
/// The CTA lives outside the scroll: on a long form (custom scope + an end
/// date) the last item of a list would be unreachable without scrolling to
/// the bottom, which is not what the frame promises.
class BudgetFormBottomBar extends StatelessWidget {
  const BudgetFormBottomBar({
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// Already localized.
  final String label;

  /// Null disables the CTA (the HU-01 gate).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }
}
