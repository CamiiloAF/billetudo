import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/toggle_field.dart';

/// The `Toggle Archivadas` field (HU-02, `gZyEC` instance): "Incluir cuentas
/// archivadas". Default `false` (excluded).
class NetWorthArchivedToggle extends StatelessWidget {
  const NetWorthArchivedToggle({
    required this.includeArchivedAccounts,
    required this.onChanged,
    super.key,
  });

  final bool includeArchivedAccounts;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ToggleField(
      icon: LucideIcons.archive,
      label: l10n.reportsNetWorthArchivedToggleLabel,
      hint: l10n.reportsNetWorthArchivedToggleHint,
      value: includeArchivedAccounts,
      onChanged: onChanged,
    );
  }
}
