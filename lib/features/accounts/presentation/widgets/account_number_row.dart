import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The account number row of the detail (HU-03).
///
/// It starts masked, always. Reveal and copy only exist for accounts whose full
/// number we are allowed to keep: a **credit card shows its `last4` and nothing
/// else** — there is no PAN stored to reveal or copy, and offering the buttons
/// would promise otherwise. That asymmetry is intentional, not an oversight.
///
/// It sits outside `InfoRow` because of those buttons.
class AccountNumberRow extends StatelessWidget {
  const AccountNumberRow({
    required this.last4,
    required this.isCard,
    this.revealedNumber,
    this.onReveal,
    this.onHide,
    this.onCopy,
    super.key,
  });

  final String? last4;

  /// A card never has a full number to act on.
  final bool isCard;

  /// Non-null only while the user is looking at it.
  final String? revealedNumber;

  final VoidCallback? onReveal;
  final VoidCallback? onHide;
  final VoidCallback? onCopy;

  bool get isRevealed => revealedNumber != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final revealedNumber = this.revealedNumber;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            l10n.accountInfoNumber,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.textSecondary),
          ),
          Expanded(
            child: Text(
              revealedNumber ?? l10n.accountNumberMasked(last4 ?? ''),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (!isCard) ...[
            IconButton(
              onPressed: isRevealed ? onHide : onReveal,
              tooltip: isRevealed
                  ? l10n.accountNumberHide
                  : l10n.accountNumberReveal,
              icon: Icon(
                isRevealed ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 20,
                color: colors.textSecondary,
              ),
            ),
            IconButton(
              onPressed: onCopy,
              tooltip: l10n.accountNumberCopy,
              icon: Icon(
                LucideIcons.copy,
                size: 20,
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
