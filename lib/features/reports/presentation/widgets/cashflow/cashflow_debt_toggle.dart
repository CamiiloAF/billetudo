import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/toggle_field.dart';

/// The `Toggle Deuda` field (HU-01, `gZyEC` instance): "Separar movimientos
/// de deuda". Wraps the domain's `includeDebtMovements` (default `true` =
/// integrated/merged) into the toggle's own ON = separated semantics, so the
/// switch reads OFF by default — matching the `.pen`'s default frame, where
/// the "Movimientos de deuda" legend starts disabled.
class CashflowDebtToggle extends StatelessWidget {
  const CashflowDebtToggle({
    required this.includeDebtMovements,
    required this.onChanged,
    super.key,
  });

  final bool includeDebtMovements;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ToggleField(
      icon: LucideIcons.landmark,
      label: l10n.reportsCashflowDebtToggleLabel,
      hint: l10n.reportsCashflowDebtToggleHint,
      value: !includeDebtMovements,
      onChanged: (separated) => onChanged(!separated),
    );
  }
}
