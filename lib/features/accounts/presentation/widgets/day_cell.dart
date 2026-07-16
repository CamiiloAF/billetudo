import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Day Cell` component: one day of the 1-31 picker.
class DayCell extends StatelessWidget {
  const DayCell({
    required this.day,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final int day;
  final bool isSelected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () => onTap(day),
        customBorder: const CircleBorder(),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            // A bare numeral, not copy: there is nothing here to translate.
            day.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? colors.onPrimary : colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
