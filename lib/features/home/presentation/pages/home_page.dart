import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_fab.dart';
import '../../../../core/widgets/coming_soon_sheet.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/ai_banner.dart';
import '../widgets/home_header.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/home_hero_skeleton.dart';
import '../widgets/quick_access_row.dart';
import '../widgets/recent_activity_row.dart';
import '../widgets/recent_activity_skeleton_row.dart';
import '../widgets/sheets/month_picker_sheet.dart';

/// The Inicio tab (feature 04): header, hero, quick access, recent activity,
/// AI banner and a scroll-aware FAB. It only reads and aggregates data
/// (HU-01…HU-10); the one write it triggers is opening the new-transaction
/// form via the FAB (HU-02).
class HomePage extends StatefulWidget {
  const HomePage({
    required this.onAddTransaction,
    required this.onSeeAllTransactions,
    required this.onOpenTransaction,
    required this.onCreateBudget,
    required this.onOpenAccounts,
    required this.onOpenScheduledPayments,
    required this.onOpenDebts,
    required this.onOpenReports,
    super.key,
  });

  final VoidCallback onAddTransaction;
  final VoidCallback onSeeAllTransactions;
  final ValueChanged<String> onOpenTransaction;
  final VoidCallback onCreateBudget;

  /// HU-05b: quick-access chip destinations.
  final VoidCallback onOpenAccounts;
  final VoidCallback onOpenScheduledPayments;
  final VoidCallback onOpenDebts;
  final VoidCallback onOpenReports;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  /// HU-02: the FAB hides on scroll down and comes back on scroll up.
  bool _fabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _fabVisible) {
      setState(() => _fabVisible = false);
    } else if (direction == ScrollDirection.forward && !_fabVisible) {
      setState(() => _fabVisible = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openMonthPicker(BuildContext context, HomeState state) async {
    final picked = await MonthPickerSheet.show(
      context,
      selected: state.month,
      currentMonth: state.currentMonth,
    );
    if (picked != null && context.mounted) {
      await context.read<HomeCubit>().selectMonth(picked);
    }
  }

  Future<void> _openBellSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ComingSoonSheet.show(
      context,
      icon: LucideIcons.bell,
      message: l10n.homeNotificationsSheetMessage,
    );
  }

  Future<void> _openAiSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ComingSoonSheet.show(
      context,
      icon: LucideIcons.sparkles,
      message: l10n.homeAiSheetMessage,
      disclaimer: l10n.homeAiDisclaimer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _fabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _fabVisible ? 1 : 0,
          child: AppFab(
            icon: LucideIcons.plus,
            tooltip: l10n.transactionsAdd,
            onPressed: widget.onAddTransaction,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: HomeHeader(
                      syncStatus: state.syncStatus,
                      user: state.user,
                      onBellTap: () => _openBellSheet(context),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: state.isLoading
                        ? const HomeHeroSkeleton()
                        : HomeHeroCard(
                            spending: state.spending!,
                            monthLabel: _monthLabel(context, state.month),
                            onMonthTap: () => _openMonthPicker(context, state),
                            onCreateBudget: widget.onCreateBudget,
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: QuickAccessRow(
                      onOpenAccounts: widget.onOpenAccounts,
                      onOpenScheduledPayments: widget.onOpenScheduledPayments,
                      onOpenDebts: widget.onOpenDebts,
                      onOpenReports: widget.onOpenReports,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                    child: RecentActivityHeader(
                      onSeeAll: widget.onSeeAllTransactions,
                      showSeeAll:
                          state.status == HomeStatus.ready && !state.isEmpty,
                    ),
                  ),
                ),
                ..._bodySlivers(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _bodySlivers(BuildContext context, HomeState state) {
    switch (state.status) {
      case HomeStatus.loading:
        return const [HomeRecentSkeletonList()];
      case HomeStatus.failure:
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: HomeFailureView(),
          ),
        ];
      case HomeStatus.ready:
        if (state.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: HomeMovementsEmptyState(onAdd: widget.onAddTransaction),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.list(
              children: [
                for (final entry in state.recentActivity)
                  RecentActivityRow(
                    entry: entry,
                    onTap: () => widget.onOpenTransaction(entry.transaction.id),
                  ),
                const SizedBox(height: 16),
                AiBanner(onTap: () => _openAiSheet(context)),
                const SizedBox(height: 96),
              ],
            ),
          ),
        ];
    }
  }

  String _monthLabel(BuildContext context, DateTime month) {
    final locale = Localizations.localeOf(context).toString();
    final raw = DateFormat.MMMM(locale).format(month);
    return raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
  }
}

/// The "Movimientos recientes" section header + "Ver todos →" link (HU-05).
class RecentActivityHeader extends StatelessWidget {
  const RecentActivityHeader({
    required this.onSeeAll,
    required this.showSeeAll,
    super.key,
  });

  final VoidCallback onSeeAll;
  final bool showSeeAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.homeRecentTitle,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (showSeeAll)
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.homeSeeAll,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primaryOnSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(LucideIcons.arrowRight,
                      size: 16, color: colors.primaryOnSoft),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The five flat skeleton rows of the loading state (HU-09).
class HomeRecentSkeletonList extends StatelessWidget {
  const HomeRecentSkeletonList({super.key});

  static const List<double> _titleWidths = [150, 120, 170, 110, 140];

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.list(
        children: [
          Semantics(
            label: AppLocalizations.of(context).homeLoading,
            child: const SizedBox.shrink(),
          ),
          for (final width in _titleWidths)
            RecentActivitySkeletonRow(titleWidth: width),
        ],
      ),
    );
  }
}

/// The recent-feed empty state (HU-08): centered between hero and tab bar,
/// with a CTA that opens the new-transaction form. No AI banner here.
class HomeMovementsEmptyState extends StatelessWidget {
  const HomeMovementsEmptyState({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(44),
              ),
              child: Icon(LucideIcons.receipt,
                  size: 40, color: colors.primaryOnSoft),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.homeEmptyMovements,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.transactionsAdd),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact, local-first failure view (HU-10): no full-screen error, and it
/// reassures that the data is safe on device.
class HomeFailureView extends StatelessWidget {
  const HomeFailureView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          l10n.transactionsErrorLocalFirst,
          textAlign: TextAlign.center,
          style:
              theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
      ),
    );
  }
}
