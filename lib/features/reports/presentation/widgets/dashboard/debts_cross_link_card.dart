import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/sheet_menu_row.dart';

/// The `Cross-link Deudas Card` (`wvAKu`, renamed from the generic
/// "Chart Cross-link Card"): HU-04's link out to Deudas. Deliberately a
/// single hardcoded case (icon `landmark`, label baked in) — see
/// `design-system/billetudo/pages/graficas.md`: a second cross-link earns its
/// own component instead of parameterizing this one speculatively.
///
/// **Never a debt-progress block of its own** (criterion 13) — Resumen only
/// links out, it does not duplicate Deudas' own numbers.
class DebtsCrossLinkCard extends StatelessWidget {
  const DebtsCrossLinkCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: SheetMenuRow(
        icon: LucideIcons.landmark,
        label: l10n.reportsDashboardCrossLinkDebts,
        onTap: onTap,
      ),
    );
  }
}
