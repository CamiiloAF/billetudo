import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debt.dart';
import '../utils/debt_format.dart';

/// The direction pill shared by `DebtCard` (`ixtP1`) and the detail hero
/// (`eipak`): text + directional icon + shape, never color alone (MASTER: tone
/// of voice, no `$expense` alarm).
///
///  - `iOwe` → neutral `$muted` pill, `$text-primary` text ("Yo debo").
///  - `owedToMe` → `$mint-soft` pill, `$income-text` text ("Me deben").
///
/// A [closed] debt (extension, HU-07) always wears the neutral `$muted`/
/// `$text-primary` treatment regardless of direction, with a past-tense label
/// ("Debía"/"Me debían") — the closed list never colors a pill green, even for
/// a debt that used to be `owedToMe` (`vaNHd`).
class DebtDirectionPill extends StatelessWidget {
  const DebtDirectionPill({
    required this.direction,
    this.closed = false,
    super.key,
  });

  final DebtDirection direction;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isOwedToMe = direction == DebtDirection.owedToMe;
    final background =
        closed ? colors.muted : (isOwedToMe ? colors.mintSoft : colors.muted);
    final foreground = closed
        ? colors.textPrimary
        : (isOwedToMe ? colors.incomeText : colors.textPrimary);
    final label = closed
        ? DebtFormat.pastDirectionLabel(l10n, direction)
        : DebtFormat.directionLabel(l10n, direction);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            DebtFormat.directionIcon(direction),
            size: 13,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
          ),
        ],
      ),
    );
  }
}
