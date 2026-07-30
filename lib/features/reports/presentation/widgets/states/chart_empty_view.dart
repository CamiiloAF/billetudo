import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/empty_state.dart';

/// HU-06 "vacío": cero movimientos en el rango. Never a chart of zeros —
/// `EmptyState` (`jmQO5`) centered with a "Agregar movimiento" CTA.
class ChartEmptyView extends StatelessWidget {
  const ChartEmptyView({required this.onAddMovement, super.key});

  final VoidCallback onAddMovement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: LucideIcons.chartColumn,
      message: l10n.reportsEmptyTitle,
      description: l10n.reportsEmptyMessage,
      ctaLabel: l10n.transactionsAdd,
      onCta: onAddMovement,
    );
  }
}
