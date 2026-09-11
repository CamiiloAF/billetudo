import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One 44×44 chevron of `PeriodNavBar`'s `Stepper Row` (`u6sSAc`/`w9Eszi`,
/// `design-system/billetudo/pages/transacciones.md` § "Period Nav Bar en la
/// pantalla principal"): `$text-primary`, dimmed to `opacity:0.4` and
/// inert when [enabled] is false — there is no window to navigate to past
/// that edge.
class PeriodNavArrowButton extends StatelessWidget {
  const PeriodNavArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Semantics(
        label: semanticLabel,
        button: true,
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, size: 22, color: colors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
