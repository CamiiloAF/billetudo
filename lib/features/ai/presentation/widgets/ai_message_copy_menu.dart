import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'ai_message_menu_row.dart';

/// The two actions a long-press on an assistant message offers.
enum AiMessageMenuAction { copy, report }

/// Wraps a message bubble with a long-press menu (`billetudo.pen`
/// `Cbssw`/`PpcIh`): "Copiar" + "Reportar", divided. Anchored to the press
/// position (`showMenu`), never a member of the scroll — the `.md` is
/// explicit that Pencil's mockup insertion into the conversation flow is
/// only a rendering shortcut, not the real interaction.
///
/// Borrows the popover surface (`$surface`, `$border`, `radius:14`,
/// `elevation:8`) already used by `TransactionsSortButton`'s popover instead
/// of inventing a new look.
class AiMessageCopyMenu extends StatelessWidget {
  const AiMessageCopyMenu({
    required this.textToCopy,
    required this.child,
    this.onReport,
    super.key,
  });

  /// Plain text copied when "Copiar" is tapped. For an assistant bubble this
  /// is only `message.content` — never the attached proposals.
  final String textToCopy;

  /// Fired when "Reportar" is tapped, after the menu has closed. `null`
  /// omits "Reportar" from the menu entirely — only an assistant bubble
  /// passes this; a user's own message can't be reported to Google Play's
  /// AI-Generated Content pipeline, it wasn't generated.
  final VoidCallback? onReport;

  final Widget child;

  Future<void> _showMenu(
    BuildContext context,
    LongPressStartDetails details,
  ) async {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final selected = await showMenu<AiMessageMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      color: colors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
      // `Cbssw`'s own width (176) — without an explicit `constraints`, the
      // popup menu's default 112px floor and step-of-56 grid would resize
      // this to whatever a single short label needs instead of the fixed
      // width the two rows share in the design.
      constraints: const BoxConstraints(minWidth: 176, maxWidth: 176),
      menuPadding: const EdgeInsets.all(4),
      items: [
        PopupMenuItem<AiMessageMenuAction>(
          value: AiMessageMenuAction.copy,
          padding: EdgeInsets.zero,
          height: 44,
          child: AiMessageMenuRow(
            icon: LucideIcons.copy,
            label: l10n.aiChatCopyMessage,
          ),
        ),
        // "Reportar" only exists for the assistant's own words (Google
        // Play's AI-Generated Content policy) — a user bubble omits
        // [onReport], and this stays a single-row menu unchanged from
        // before that requirement existed.
        if (onReport != null) ...[
          PopupMenuDivider(height: 1, thickness: 1, color: colors.border),
          PopupMenuItem<AiMessageMenuAction>(
            value: AiMessageMenuAction.report,
            padding: EdgeInsets.zero,
            height: 44,
            child: AiMessageMenuRow(
              icon: LucideIcons.flag,
              label: l10n.aiMessageActionReport,
            ),
          ),
        ],
      ],
    );

    if (!context.mounted) {
      return;
    }
    switch (selected) {
      case AiMessageMenuAction.copy:
        await Clipboard.setData(ClipboardData(text: textToCopy));
      case AiMessageMenuAction.report:
        onReport?.call();
      case null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onLongPressStart: (details) => _showMenu(context, details),
        child: child,
      );
}
