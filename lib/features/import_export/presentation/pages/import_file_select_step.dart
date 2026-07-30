import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../core/widgets/neutral_button.dart';
import '../../../../core/widgets/sheet_buttons_row.dart';

/// HU-05 entry (`W2hiZK`/`rsBfI`): a modal-bottom-sheet-styled step
/// ("Cancelar" + "Elegir archivo") that triggers the OS's native file
/// picker. The picker itself is system UI, not designed in Pencil.
///
/// `ImportFlowPage` renders this inside its own scrim-backed sheet chrome
/// (see `_ImportFileSelectSheetChrome`) rather than a real
/// `showModalBottomSheet` route: the wizard's cubit state and this step live
/// on the same routed page, so a nested modal route would fight with
/// `ImportFlowCubit`'s own step transitions once a file is picked.
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
