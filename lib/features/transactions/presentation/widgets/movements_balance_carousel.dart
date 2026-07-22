import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/preferences/balance_carousel_cubit.dart';
import '../../../../core/preferences/balance_carousel_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../cubit/transactions_list_state.dart';
import 'movements_balance_card.dart';

/// The collapsible balance carousel of Movimientos (Mejora #2): a horizontal
/// [PageView] of one [MovementsBalanceCard] per shown account, with a collapse
/// handle above and pagination dots below. Collapsed, it shrinks to a single
/// compact bar ("N cuentas · Saldo total $X"). Both the collapsed/expanded
/// state and the active card index are owned by [BalanceCarouselCubit].
class MovementsBalanceCarousel extends StatelessWidget {
  const MovementsBalanceCarousel({
    required this.state,
    required this.onOpenAccount,
    super.key,
  });

  final TransactionsListState state;

  /// Opens the detail page of the account whose card is tapped (only in the
  /// expanded carousel; the collapsed bar just reexpands).
  final ValueChanged<String> onOpenAccount;

  @override
  Widget build(BuildContext context) {
    // Nothing to show until accounts have loaded, or when the filter resolves
    // to no account at all: the carousel simply takes no vertical space.
    if (state.displayedAccounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<BalanceCarouselCubit, BalanceCarouselState>(
      builder: (context, carousel) => carousel.collapsed
          ? MovementsBalanceCarouselCollapsed(state: state)
          : MovementsBalanceCarouselExpanded(
              state: state,
              initialPage: carousel.currentPage,
              onOpenAccount: onOpenAccount,
            ),
    );
  }
}

/// The compact one-line bar shown while the carousel is collapsed. The whole
/// bar reexpands the carousel on tap.
class MovementsBalanceCarouselCollapsed extends StatelessWidget {
  const MovementsBalanceCarouselCollapsed({required this.state, super.key});

  final TransactionsListState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final accounts = state.displayedAccounts;
    final total = const MoneyFormatter().formatSymbol(
      state.displayedBalanceTotalMinor,
      currencyCode: state.displayedCurrency,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Semantics(
        button: true,
        label: l10n.transactionsBalanceCarouselExpand,
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            onTap: context.read<BalanceCarouselCubit>().expand,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.layers,
                      size: 18,
                      color: colors.primaryOnSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // "N cuentas" flexes and may ellipsize; the total keeps
                  // priority so the amount always renders on one line,
                  // un-truncated (the visible "Saldo total" label was dropped
                  // for space — screen readers still get it via semanticsLabel).
                  Expanded(
                    child: Text(
                      l10n.transactionsFilterAccountsSelected(accounts.length),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    total,
                    maxLines: 1,
                    semanticsLabel: '${l10n.transactionsBalanceTotalLabel}: '
                        '$total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The full carousel: collapse handle, the swipeable cards, and the dots.
class MovementsBalanceCarouselExpanded extends StatefulWidget {
  const MovementsBalanceCarouselExpanded({
    required this.state,
    required this.initialPage,
    required this.onOpenAccount,
    super.key,
  });

  final TransactionsListState state;

  /// The card to open on: the cubit's remembered active page, so reopening
  /// after a collapse (or swiping and returning) lands on the same account.
  final int initialPage;

  /// Forwarded to each card: tapping it opens that account's detail page.
  final ValueChanged<String> onOpenAccount;

  @override
  State<MovementsBalanceCarouselExpanded> createState() =>
      _MovementsBalanceCarouselExpandedState();
}

class _MovementsBalanceCarouselExpandedState
    extends State<MovementsBalanceCarouselExpanded> {
  late final PageController _controller = PageController(
    initialPage: _clampedPage(widget.initialPage),
    viewportFraction: 0.88,
  );
  late int _page = _clampedPage(widget.initialPage);

  /// The last valid card index, so neither the dots nor the controller ever
  /// point past the shown accounts (the filter can shrink the set).
  int _clampedPage(int page) {
    final lastPage = widget.state.displayedAccounts.length - 1;
    if (lastPage < 0) {
      return 0;
    }
    return page.clamp(0, lastPage);
  }

  @override
  void didUpdateWidget(covariant MovementsBalanceCarouselExpanded oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The filter can shrink the account set out from under the current page
    // (e.g. switching from "Todas" to a single account): clamp so the dots and
    // controller never point past the last card.
    final clamped = _clampedPage(_page);
    if (clamped != _page) {
      _page = clamped;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToPage(clamped);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    context.read<BalanceCarouselCubit>().pageChanged(page);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = widget.state.displayedAccounts;

    return Column(
      children: [
        MovementsBalanceCollapseHandle(
          onTap: context.read<BalanceCarouselCubit>().collapse,
        ),
        const SizedBox(height: 2),
        if (accounts.length == 1)
          // A lone card has no next page to peek at, so it takes the full
          // width and centres instead of hugging the left with a phantom gap.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MovementsBalanceCard(
              entry: accounts.first,
              onOpenAccount: widget.onOpenAccount,
            ),
          )
        else ...[
          SizedBox(
            height: MovementsBalanceCard.height,
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              itemCount: accounts.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: index == accounts.length - 1 ? 20 : 8,
                ),
                child: MovementsBalanceCard(
                  entry: accounts[index],
                  onOpenAccount: widget.onOpenAccount,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          MovementsBalanceDots(count: accounts.length, active: _page),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

/// The thin `muted` pill + `chevron-up` above the cards. Tapping it collapses
/// the carousel.
class MovementsBalanceCollapseHandle extends StatelessWidget {
  const MovementsBalanceCollapseHandle({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n.transactionsBalanceCarouselCollapse,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                LucideIcons.chevronUp,
                size: 18,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pagination dots under the cards: the active page's dot is `primary`, the
/// rest `muted`.
class MovementsBalanceDots extends StatelessWidget {
  const MovementsBalanceDots({
    required this.count,
    required this.active,
    super.key,
  });

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.accountBalancePage(active + 1, count),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var page = 0; page < count; page++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: page == active ? colors.primary : colors.muted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
