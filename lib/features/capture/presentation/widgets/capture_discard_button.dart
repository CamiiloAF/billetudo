import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The per-card discard affordance of the Avisos centre (`Bk8zW`): dismiss a
/// capture that was never going to be registered, without opening the
/// transaction form first.
///
/// **Reversible on purpose.** It delegates to the existing
/// `NoticesCubit.discard` → `DiscardPendingCapture` flow, which moves the row
/// to `discarded` (never a physical delete) and hands the page the
/// "Captura descartada · Deshacer" snackbar. Because the action is undoable,
/// there is no confirmation sheet: a modal would add a tap to the one action
/// the user already committed to, and the system's `Confirmar Eliminar`
/// pattern is reserved for irreversible deletions.
///
/// This is the only control that competes with the card's own tap target
/// (dispatch to the form), which is why it is a real 44x44 button instead of
/// a painted glyph: the parent `InkWell` would otherwise turn a near-miss
/// into "open the form". It sits where the card used to show `chevron-right`:
/// two trailing glyphs for two different destinations would read as one group
/// and shrink the merchant column further.
class CaptureDiscardButton extends StatelessWidget {
  const CaptureDiscardButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return IconButton(
      onPressed: onPressed,
      tooltip: l10n.captureDiscardAction,
      style: IconButton.styleFrom(
        // `$text-secondary`, never `$expense`: the discard is undoable, so it
        // is a quiet secondary action, not a red irreversible one.
        foregroundColor: colors.textSecondary,
        // 44x44 is this project's minimum tap target (same convention as
        // `NoticeBellButton`); the glyph stays small so the card keeps its
        // typographic hierarchy. `shrinkWrap` stops the Material default from
        // inflating it to 48, which the card's trailing cluster can't absorb.
        fixedSize: const Size.square(44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(LucideIcons.x, size: 18),
    );
  }
}
