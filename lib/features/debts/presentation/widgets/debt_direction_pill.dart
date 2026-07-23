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
class DebtDirectionPill extends StatelessWidget {
  const DebtDirectionPill({required this.direction, super.key});

  final DebtDirection direction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isOwedToMe = direction == DebtDirection.owedToMe;
    final background = isOwedToMe ? colors.mintSoft : colors.muted;
    final foreground = isOwedToMe ? colors.incomeText : colors.textPrimary;

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
            DebtFormat.directionLabel(l10n, direction),
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
