import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/presentation/widgets/account_type_avatar.dart';
import '../../../accounts/presentation/widgets/credit_usage_bar.dart';

/// One page of the Movimientos balance carousel (Mejora #2): an account's
/// balance at a glance. Both variants mirror the same structure (variant A2):
/// a full-width identity on top (avatar + name + type) and a labelled figure
/// block below. A non-card account's block is a single "Saldo" figure; a credit
/// card's block is a usage bar plus a Deuda/Cupo disponible pair. Because the
/// name owns the full width — never competing with a hero amount on its row —
/// it can wrap to two lines instead of truncating. Both variants share [height]
/// so the carousel's cards never jump in size as the user swipes.
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
  ///
  /// Sized to hold a two-line name in the *taller* (credit) variant without
  /// clipping: the A2 mock reads ~124px, but Flutter's real line metrics (the
  /// brand text theme is bigger than the mock's compact type, and Pencil does
  /// not render line-height the same way) push a two-line credit card past
  /// that. This is the value verified not to overflow with a long name in
  /// either variant — see `movements_balance_card_test.dart`.
  static const double height = 150;

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              // The name owns the full card width here (no hero amount shares
              // its row), so it wraps to a second line instead of truncating.
              // Only a name longer than two lines ellipsizes (A2).
              Text(
                account.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  height: 1.25,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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

/// Non-card variant: identity on top, then a single labelled "Saldo" figure —
/// the same [MovementsBalanceCardFigure] the credit variant uses for its
/// Deuda/Cupo pair, so the two cards read as one family when swiped (A2). No
/// usage bar: a plain account has no credit limit.
class MovementsBalanceCardSimple extends StatelessWidget {
  const MovementsBalanceCardSimple({required this.entry, super.key});

  final AccountWithBalance entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final account = entry.account;
    final balanceMinor = entry.balance.balanceMinor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MovementsBalanceCardIdentity(entry: entry),
        const SizedBox(height: 10),
        MovementsBalanceCardFigure(
          label: l10n.transactionsBalanceCardBalanceLabel,
          amount: const MoneyFormatter()
              .formatSymbol(balanceMinor, currencyCode: account.currency),
          // A negative balance reads as a debt/overdraft in red; anything else
          // stays neutral (never green — positive is the baseline, HU-04).
          // Small text needs `expenseText` for 4.5:1, matching the credit
          // Deuda figure.
          color: balanceMinor < 0 ? colors.expenseText : colors.textPrimary,
          alignEnd: false,
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MovementsBalanceCardIdentity(entry: entry),
        const SizedBox(height: 10),
        CreditUsageBar(
          balance: balance,
          creditLimitMinor: account.creditLimitMinor ?? 0,
        ),
        const SizedBox(height: 6),
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
                // Small (16px) red text needs `expenseText` for 4.5:1 — plain
                // `$expense` only clears the 3:1 large-text bar and fails on the
                // dark surface (MASTER's expense vs expense-text rule).
                color: colors.expenseText,
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
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
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
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
