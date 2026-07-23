import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Switch` component (`bWezV`, `reusable:true`): a 48×28 track that fills
/// `$primary` when on and `$muted` when off, with a `$on-primary` knob carrying
/// a `$border` stroke and an iOS-style shadow so the OFF knob keeps contrast
/// against the light track.
///
/// The whole row is the tap target at the call site (`deudas.md`), so this
/// widget itself paints only the pill.
class DebtCashSwitch extends StatelessWidget {
  const DebtCashSwitch({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? colors.primary : colors.muted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: colors.onPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x29000000),
                  blurRadius: 2,
                ),
                BoxShadow(
                  color: Color(0x3D000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
