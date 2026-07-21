import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_balance.dart';

import 'credit_usage_bar.dart';
import 'over_limit_badge.dart';

/// The `Balance Card Hero` component: a credit card's headline figure, as a
/// carousel between available credit and debt (HU-04).
///
/// Two dots are the only affordance — chevrons were tried and dropped, the user
/// accepting the discoverability risk `ui-ux-reviewer` raised. The progress bar
/// and caption stay fixed under both pages: they describe the card, not the
/// page.
class BalanceCardHero extends StatefulWidget {
  const BalanceCardHero({
    required this.balance,
    required this.currency,
    required this.creditLimitMinor,
    required this.view,
    this.onViewChanged,
    super.key,
  });

  final AccountBalance balance;
  final String currency;
  final int creditLimitMinor;

  /// Which page opens first: the account's stored preference.
  final CardBalanceView view;

  final ValueChanged<CardBalanceView>? onViewChanged;

  /// Carousel order, fixed by the design: available credit, then debt.
  static const List<CardBalanceView> pages = [
    CardBalanceView.available,
    CardBalanceView.debt,
  ];

  @override
  State<BalanceCardHero> createState() => _BalanceCardHeroState();
}

class _BalanceCardHeroState extends State<BalanceCardHero> {
  late int _index = BalanceCardHero.pages.indexOf(widget.view);
  late final PageController _controller =
      PageController(initialPage: _index < 0 ? 0 : _index);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    widget.onViewChanged?.call(BalanceCardHero.pages[index]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();
    final balance = widget.balance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 116,
            child: PageView(
              controller: _controller,
              onPageChanged: _onPageChanged,
              children: [
                BalanceHeroFigure(
                  label: l10n.accountAvailableCreditLabel,
                  // Floored at 0 by the domain: an overspent card shows $0
                  // available, never a negative "credit" (HU-02).
                  amount: money.formatSymbol(
                    balance.availableCreditMinor ?? 0,
                    currencyCode: widget.currency,
                  ),
                  color: colors.textPrimary,
                  showOverLimitBadge: balance.overLimit,
                ),
                BalanceHeroFigure(
                  label: l10n.accountDebtLabel,
                  amount: money.formatSymbol(
                    balance.debtMinor,
                    currencyCode: widget.currency,
                  ),
                  color: colors.expense,
                  showOverLimitBadge: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: l10n.accountBalancePage(
              _index + 1,
              BalanceCardHero.pages.length,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var page = 0; page < BalanceCardHero.pages.length; page++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: page == _index ? colors.primary : colors.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CreditUsageBar(
            balance: balance,
            creditLimitMinor: widget.creditLimitMinor,
          ),
          const SizedBox(height: 8),
          Text(
            balance.overLimit
                ? l10n.accountOverLimitCaption(
                    money.formatSymbol(
                      balance.excessMinor,
                      currencyCode: widget.currency,
                    ),
                  )
                : l10n.accountCreditUsedCaption(
                    money.formatSymbol(
                      balance.debtMinor,
                      currencyCode: widget.currency,
                    ),
                    money.formatSymbol(
                      widget.creditLimitMinor,
                      currencyCode: widget.currency,
                    ),
                  ),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// One page of the hero: label + figure, plus the over-limit badge when the
/// figure needs the caveat.
class BalanceHeroFigure extends StatelessWidget {
  const BalanceHeroFigure({
    required this.label,
    required this.amount,
    required this.color,
    required this.showOverLimitBadge,
    super.key,
  });

  final String label;
  final String amount;
  final Color color;
  final bool showOverLimitBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall
              ?.copyWith(fontWeight: FontWeight.w800, color: color),
        ),
        if (showOverLimitBadge) ...[
          const SizedBox(height: 8),
          const OverLimitBadge(),
        ],
      ],
    );
  }
}
