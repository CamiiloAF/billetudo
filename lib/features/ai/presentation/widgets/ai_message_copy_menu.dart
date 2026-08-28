import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Wraps a message bubble with a long-press "Copiar" menu. No frame exists
/// for this in `billetudo.pen` — it is a standard platform interaction
/// (`showMenu` anchored to the press position), not a designed screen — so
/// it borrows the popover surface (`$surface`, `$border`, `radius:12`,
/// `elevation:8`) already used by `TransactionsSortButton`'s popover instead
/// of inventing a new look.
class AiMessageCopyMenu extends StatelessWidget {
  const AiMessageCopyMenu({
    required this.textToCopy,
    required this.child,
    super.key,
  });

  /// Plain text copied when "Copiar" is tapped. For an assistant bubble this
  /// is only `message.content` — never the attached proposals.
  final String textToCopy;

  final Widget child;

  Future<void> _showCopyMenu(
    BuildContext context,
    LongPressStartDetails details,
  ) async {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final selected = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      color: colors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      // The menu's own width grid (`_kMenuWidthStep` = 56 in Material's
      // popup_menu.dart) can't be overridden, but its default 112px floor
      // can — without it, a single short-label item like "Copiar" no longer
      // pads out to a 3-step-wide (168px) square.
      constraints: const BoxConstraints(),
      items: [
        PopupMenuItem<bool>(
          value: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          height: 44,
          child: Text(l10n.aiChatCopyMessage),
        ),
      ],
    );

    if (selected != true || !context.mounted) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: textToCopy));
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onLongPressStart: (details) => _showCopyMenu(context, details),
        child: child,
      );
}
