import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The `Switch` component (`bWezV`, `reusable:true` in `billetudo.pen`): a
/// 48x28 track filled `$primary` when on, with a `$on-primary` knob carrying
/// a `$border` stroke and a small drop shadow so it keeps contrast against
/// the track in both states.
///
/// The OFF track uses `$text-secondary`, not the component's original
/// `$border` — an accessibility fix documented in
/// `design-system/billetudo/pages/transacciones.md` (Adición 2026-07-24):
/// `$border` failed the 3:1 WCAG 1.4.11 minimum against `$surface` in both
/// themes (~2:1). `$text-secondary` clears it (~4.9:1 light, ~5.9:1 dark).
///
/// Purely visual: the tap target is the call site's job. `ToggleField` wraps
/// the whole row, not just this widget, per the same doc's accessibility
/// note (the switch alone measures 48x28, under the 44x44 minimum).
class AppSwitch extends StatelessWidget {
  const AppSwitch({required this.value, super.key});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeInOut,
      width: 48,
      height: 28,
      padding: const EdgeInsets.all(3),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: value ? colors.primary : colors.textSecondary,
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
            BoxShadow(color: Color(0x29000000), blurRadius: 2),
            BoxShadow(
              color: Color(0x3D000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
