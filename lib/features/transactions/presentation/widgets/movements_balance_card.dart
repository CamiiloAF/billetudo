import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/presentation/widgets/account_type_avatar.dart';
import '../../../accounts/presentation/widgets/credit_usage_bar.dart';

/// One page of the Movimientos balance carousel (Mejora #2): an account's
/// balance at a glance. A non-card account shows its name, type and a single
/// balance figure; a credit card swaps the figure for a usage bar plus a
/// Deuda/Cupo disponible pair. Both variants share [height] so the
/// carousel's cards never jump in size as the user swipes between accounts.
class MovementsBalanceCard extends StatelessWidget {
  const MovementsBalanceCard({
    required this.entry,
    required this.onOpenAccount,
    super.key,
  });

  final AccountWithBalance entry;

  /// Opens the account's detail page. A tap navigates; the surrounding
  /// [PageView] keeps the horizontal drag for paging — `InkWell.onTap` only
  /// fires on a tap, never on a drag, so the two gestures do not fight.
  final ValueChanged<String> onOpenAccount;

  /// Fixed so the credit-card variant (bar + two figures) and the plain
  /// variant (one figure) line up in the same [PageView] without resizing it.
  /// Exposed so the carousel's [PageView] can bound itself to the same height.
  static const double height = 160;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final account = entry.account;

    return SizedBox(
      height: height,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => onOpenAccount(account.id),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: colors.border),
            ),
            child: account.isCard
                ? MovementsBalanceCardCredit(entry: entry)
                : MovementsBalanceCardSimple(entry: entry),
          ),
        ),
      ),
    );
  }
}

/// The identity block shared by both variants: avatar + name + type label.
class MovementsBalanceCardIdentity extends StatelessWidget {
  const MovementsBalanceCardIdentity({required this.entry, super.key});

  final AccountWithBalance entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final account = entry.account;

    return Row(
      children: [
        AccountTypeAvatar(type: account.type),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                account.type.label(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Non-card variant: identity on the left, one balance figure on the right,
/// centred in the fixed card height.
class MovementsBalanceCardSimple extends StatelessWidget {
  const MovementsBalanceCardSimple({required this.entry, super.key});

  final AccountWithBalance entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final account = entry.account;
    final balanceMinor = entry.balance.balanceMinor;

    return Row(
      children: [
        Expanded(child: MovementsBalanceCardIdentity(entry: entry)),
        const SizedBox(width: 12),
        // A long figure (e.g. `$12.400.000`) would otherwise squeeze the name
        // out: `FittedBox` scales the amount down to fit its share instead of
        // truncating money, and never upscales the short common case.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              const MoneyFormatter()
                  .formatSymbol(balanceMinor, currencyCode: account.currency),
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                // Negative reads as a debt/overdraft in `$expense`; anything
                // else stays neutral (never green — positive is the baseline,
                // HU-04).
                color: balanceMinor < 0 ? colors.expense : colors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Credit-card variant: identity, then the usage bar, then a Deuda/Cupo
/// disponible pair — the same figures HU-02/HU-04 defines on Cuentas.
class MovementsBalanceCardCredit extends StatelessWidget {
  const MovementsBalanceCardCredit({required this.entry, super.key});

  final AccountWithBalance entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final account = entry.account;
    final balance = entry.balance;
    const money = MoneyFormatter();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MovementsBalanceCardIdentity(entry: entry),
        const SizedBox(height: 14),
        CreditUsageBar(
          balance: balance,
          creditLimitMinor: account.creditLimitMinor ?? 0,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MovementsBalanceCardFigure(
                label: l10n.accountDebtLabel,
                amount: money.formatSymbol(
                  balance.debtMinor,
                  currencyCode: account.currency,
                ),
                color: colors.expense,
                alignEnd: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MovementsBalanceCardFigure(
                label: l10n.accountAvailableCreditLabel,
                // Floored at 0 by the domain: an overspent card shows $0
                // available, never a negative figure (HU-04).
                amount: money.formatSymbol(
                  balance.availableCreditMinor ?? 0,
                  currencyCode: account.currency,
                ),
                color: colors.textPrimary,
                alignEnd: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A labelled figure in the credit-card variant's bottom row.
class MovementsBalanceCardFigure extends StatelessWidget {
  const MovementsBalanceCardFigure({
    required this.label,
    required this.amount,
    required this.color,
    required this.alignEnd,
    super.key,
  });

  final String label;
  final String amount;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final cross =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;

    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
