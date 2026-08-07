import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../core/widgets/sheet_buttons_row.dart';
import '../../domain/entities/backup_header.dart';
import '../widgets/replace_all_ack_row.dart';

/// The escalated "Reemplazar todo" confirmation (`NY5o6`/`MjNwC`, HU-04): its
/// own step, not embedded at the bottom of the mode-choice summary — a
/// warning icon, an irreversibility notice and a checkbox that must be
/// checked before the destructive `$expense` CTA enables.
///
/// A direct `Column(mainAxisSize: MainAxisSize.min)` — not centered inside
/// an unbounded-height parent — so the modal sheet it renders inside
/// (`RestoreSheet`) sizes to this content instead of stretching to fill the
/// screen; same shape `UndoImportConfirmSheet` already uses for another
/// confirmation sheet. No extra horizontal padding either: `BottomSheetBase`
/// already provides it.
class RestoreReplaceAllConfirmStep extends StatelessWidget {
  const RestoreReplaceAllConfirmStep({
    required this.header,
    required this.acknowledged,
    required this.onAcknowledgedChanged,
    required this.onCancel,
    required this.onConfirm,
    super.key,
  });

  final BackupHeader header;
  final bool acknowledged;
  final ValueChanged<bool> onAcknowledgedChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.triangleAlert,
          iconColor: colors.expense,
          iconBackground: colors.expenseSoft,
          title: l10n.importExportReplaceAllConfirmTitle,
          message: l10n.importExportReplaceAllConfirmBody(
            DateFormat.yMMMMd(l10n.localeName).format(header.createdAt),
          ),
        ),
        const SizedBox(height: 20),
        ReplaceAllAckRow(
          text: l10n.importExportReplaceAllAck,
          checked: acknowledged,
          onTap: () => onAcknowledgedChanged(!acknowledged),
        ),
        const SizedBox(height: 20),
        SheetButtonsRow(
          left: OutlinedButton(
              onPressed: onCancel, child: Text(l10n.commonCancel)),
          right: FilledButton.icon(
            style: acknowledged
                ? FilledButton.styleFrom(backgroundColor: colors.expense)
                : null,
            onPressed: acknowledged ? onConfirm : null,
            icon: const Icon(LucideIcons.replace, size: 18),
            label: Text(l10n.importExportRestoreConfirmReplaceCta),
          ),
        ),
      ],
    );
  }
}
