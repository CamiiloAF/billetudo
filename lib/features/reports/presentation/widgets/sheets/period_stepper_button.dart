import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'period_selector_sheet.dart' show PeriodSelectorSheet;

/// The prev/next chevron of [PeriodSelectorSheet]'s month/year stepper.
class PeriodStepperButton extends StatelessWidget {
  const PeriodStepperButton({required this.icon, required this.onTap, super.key});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: colors.textPrimary),
        ),
      ),
    );
  }
}
