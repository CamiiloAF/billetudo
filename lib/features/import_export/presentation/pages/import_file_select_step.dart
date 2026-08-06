import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../core/widgets/neutral_button.dart';
import '../../../../core/widgets/sheet_buttons_row.dart';

/// Former HU-05 entry sheet (`W2hiZK`/`rsBfI`, marked OBSOLETO en
/// `billetudo.pen`, decisión 2026-08-06): `ImportFlowPage` no longer shows
/// this as the wizard's entry step — "Importar desde un CSV" opens the OS's
/// native file picker directly, with no intermediate sheet.
///
/// Kept only as `ImportFlowBody`'s defensive fallback for the (should never
/// happen) case of reaching the mapping step without a parsed sample.
class ImportFileSelectStep extends StatelessWidget {
  const ImportFileSelectStep({
    required this.onPickFile,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onPickFile;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.fileInput,
          iconColor: colors.mint,
          iconBackground: colors.mintSoft,
          title: l10n.importExportSelectFileTitle,
          message: l10n.importExportSelectFileBody,
        ),
        const SizedBox(height: 20),
        SheetButtonsRow(
          left: OutlinedButton(onPressed: onCancel, child: Text(l10n.commonCancel)),
          right: NeutralButton(
            label: l10n.importExportSelectFileCta,
            icon: LucideIcons.folderOpen,
            onPressed: onPickFile,
          ),
        ),
      ],
    );
  }
}
