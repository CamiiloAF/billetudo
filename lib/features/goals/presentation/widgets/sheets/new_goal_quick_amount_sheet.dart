import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../currency_pill.dart';
import '../goal_amount_hero_field.dart';

/// "+ Nueva" (`urHlG`/`MqLys` oscuro): a minimal sheet — just the Monto field
/// and a "Crear chip" CTA, no fecha/nota/enlazar like the full Aportar sheet.
/// Purely a text prompt: resolves to the entered `amountMinor`, or `null` if
/// dismissed. The actual write (and where the new chip appears in the row)
/// lives in `GoalDetailCubit.createQuickAmount`, called by the caller once
/// this pops — same precedent as `NewTagSheet`/`CreateTag`.
class NewGoalQuickAmountSheet extends StatefulWidget {
  const NewGoalQuickAmountSheet({required this.currency, super.key});

  final String currency;

  static Future<int?> show(BuildContext context, {required String currency}) =>
      BottomSheetBase.show<int>(
        context,
        builder: (context) => NewGoalQuickAmountSheet(currency: currency),
      );

  @override
  State<NewGoalQuickAmountSheet> createState() =>
      _NewGoalQuickAmountSheetState();
}

class _NewGoalQuickAmountSheetState extends State<NewGoalQuickAmountSheet> {
  int _amountMinor = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.goalNewQuickAmountTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.goalNewQuickAmountSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          GoalAmountHeroField(
            fieldKey: const ValueKey('goal-new-quick-amount'),
            label: l10n.goalQuickAmountFieldLabel,
            currency: widget.currency,
            initialAmountMinor: _amountMinor,
            onChanged: (amountMinor) =>
                setState(() => _amountMinor = amountMinor),
            autofocus: true,
            compact: true,
            compactTrailing:
                CurrencyPill(label: widget.currency, locked: false),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _amountMinor > 0
                  ? () => Navigator.of(context).pop(_amountMinor)
                  : null,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(l10n.goalNewQuickAmountCta),
            ),
          ),
        ],
      ),
    );
  }
}
