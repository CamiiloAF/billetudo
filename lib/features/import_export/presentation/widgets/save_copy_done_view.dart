import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neutral_button.dart';
import '../../../../core/widgets/sheet_buttons_row.dart';

/// HU-03's closing step, once the `.billetudo.json` copy finished writing:
/// offers "Guardar" (primary — writes the file to wherever the user picks
/// through the OS's native save dialog) and "Compartir" (secondary — the
/// existing share-sheet flow) as two separate actions, instead of jumping
/// straight to the share sheet as the only way out.
///
/// No dedicated frame exists for this step in `billetudo.pen`
/// (`design-system/billetudo/pages/import-export.md` documents that HU-03's
/// "listo" state was never drawn — the flow went straight from progress to
/// the OS share sheet). This reuses the same shrink-wrapped icon+title
/// layout as `RestoreSheetBody`'s `done` case and `ImportSummaryStep`'s two
/// `Sheet Buttons Row` (`Ot4yI`) actions, both already-approved instances of
/// the shared pattern, to stay consistent instead of inventing a new one.
class SaveCopyDoneView extends StatelessWidget {
  const SaveCopyDoneView({required this.onSave, required this.onShare, super.key});

  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colors.tealSoft, shape: BoxShape.circle),
          child: Icon(LucideIcons.shieldCheck, size: 32, color: colors.teal),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.importExportSaveCopyDoneTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.importExportSaveCopyDoneBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: 20),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: onShare,
            child: Text(
              l10n.importExportSaveCopyActionShare,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          right: NeutralButton(
            label: l10n.importExportSaveCopyActionSave,
            icon: LucideIcons.download,
            onPressed: onSave,
          ),
        ),
      ],
    );
  }
}
