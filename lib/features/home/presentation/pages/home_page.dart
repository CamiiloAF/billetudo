import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_fab.dart';
import '../../../../core/widgets/coming_soon_sheet.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../accounts/presentation/utils/show_account_gate_if_needed.dart';
import '../../../accounts/presentation/widgets/account_gate_copy.dart';
import '../../../capture/presentation/utils/start_voice_capture_flow.dart';
import '../../../settings/presentation/cubit/app_settings_cubit.dart';
import '../../../settings/presentation/cubit/app_settings_state.dart';
import '../../../tutorials/domain/entities/tutorial_key.dart';
import '../../../tutorials/presentation/widgets/tutorial_auto_show.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/ai_card.dart';
import '../widgets/home_header.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/home_hero_skeleton.dart';
import '../widgets/quick_access_row.dart';
import '../widgets/recent_activity_row.dart';
import '../widgets/recent_activity_skeleton_row.dart';
import '../widgets/sheets/account_sheet.dart';
import '../widgets/sheets/balances_sheet.dart';
import '../widgets/sheets/month_picker_sheet.dart';

/// The Inicio tab (feature 04): header, hero, AI card, quick access, recent
/// activity and a scroll-aware FAB. It only reads and aggregates data
/// (HU-01…HU-10); the one write it triggers is opening the new-transaction
/// form via the FAB (HU-02).
class HomePage extends StatefulWidget {
  const HomePage({
    required this.onAddTransaction,
    required this.onSeeAllTransactions,
    required this.onOpenTransaction,
    required this.onCreateBudget,
    required this.onOpenBudget,
    required this.onOpenAccounts,
    required this.onOpenAccountMovements,
    required this.onAddAccount,
    required this.onOpenScheduledPayments,
    required this.onOpenDebts,
    required this.onOpenReports,
    required this.onOpenGoals,
    required this.onOpenQuickAccessOrder,
    required this.onOpenLogin,
    required this.onOpenSyncStatus,
    required this.onOpenSettings,
    required this.onSignOut,
    required this.onOpenAi,
    required this.onOpenAiInsightQuestion,
    required this.onOpenAiConversation,
    super.key,
  });

  final VoidCallback onAddTransaction;
  final VoidCallback onSeeAllTransactions;

  /// Navigates to the detail page and resolves with whatever it popped with
  /// (the deleted transaction's id, or `null`).
  final Future<String?> Function(String id) onOpenTransaction;
  final VoidCallback onCreateBudget;

  /// Criterion 6: tapping the hero when a budget is featured opens *that*
  /// budget's own detail (`AppRoutes.budget`) — never a movements list.
  final ValueChanged<String> onOpenBudget;

  /// HU-05b: quick-access chip destinations.
  final VoidCallback onOpenAccounts;

  /// Criterion 4: tapping a row in the "Tu dinero" balances sheet opens
  /// Movimientos filtered to that account only — never an account detail.
  final ValueChanged<String> onOpenAccountMovements;

  /// The "Tu dinero" empty state's CTA (GH-24): with no active account, the
  /// sheet closes itself before this fires — same as [onOpenAccountMovements]
  /// — and points to the same new-account form the account gate (`15-gate-
  /// cuenta.md`) and Cuentas' own empty state already use.
  final VoidCallback onAddAccount;

  final VoidCallback onOpenScheduledPayments;
  final VoidCallback onOpenDebts;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenGoals;

  /// Opens Ajustes > "Orden del acceso rapido" from the gear that closes the
  /// quick-access strip. Not a chip destination: it is where the strip's
  /// own order is set.
  final VoidCallback onOpenQuickAccessOrder;

  /// Opens the backup/login flow: routed to both from a sync badge in
  /// attention with no session, and from "Tu cuenta"'s "sin cuenta" CTA
  /// ("Activar respaldo").
  final VoidCallback onOpenLogin;

  /// Opens "Estado de sincronización" from "Tu cuenta"'s sync block. The
  /// block never navigates itself; the Home owns the destination.
  final VoidCallback onOpenSyncStatus;

  /// Opens Ajustes from "Tu cuenta"'s "Ajustes" row.
  final VoidCallback onOpenSettings;

  /// "Cerrar sesión" from "Tu cuenta" — same confirmation flow as Más.
  final VoidCallback onSignOut;

  /// Opens the assistant (`asistente-ia.md`) from the AI card/chips, already
  /// gated: only called once the tap-time access check passed. `question`
  /// carries the tapped chip's text (`null` for the header/generic tap),
  /// pre-seeding a brand-new thread instead of resuming the last one.
  final void Function(String? question) onOpenAi;

  /// The AI card insight's own chip when it has no linked conversation yet
  /// (bugfix item 7): starts a brand-new thread seeded with `question` and,
  /// unlike [onOpenAi], links that thread to the insight it came from —
  /// `insightType` is `HomeAiInsightType.name`, `null` only for
  /// `createBudget` (which never reaches this callback; its chip is a direct
  /// navigation). Returns once the assistant screen is popped back, so the
  /// caller can refresh `HomeCubit`'s resolved conversation link with a
  /// `BuildContext`/cubit reference it already holds — the router must not
  /// do that refresh itself (its own `context` sits above `HomeCubit`'s
  /// provider).
  final Future<void> Function({
    required String question,
    required String? insightType,
  }) onOpenAiInsightQuestion;

  /// The AI card insight's own chip once it already has a linked
  /// conversation: reopens that exact thread — never whatever conversation
  /// is most recently active in general, which was the bug. Same "returns
  /// once popped back" contract as [onOpenAiInsightQuestion].
  final Future<void> Function(String conversationId) onOpenAiConversation;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  /// HU-02: the FAB hides on scroll down and comes back on scroll up.
  bool _fabVisible = true;

  /// Guards every AI-card tap handler below (`_onAskQuestion`,
  /// `_onCreateBudgetOrAskAi`, `_onStartInsightConversation`,
  /// `_onContinueInsightConversation`) against opening the chat more than
  /// once. Each of them is `async` with a real `await` (the access-gate
  /// check) before it navigates — reported live: tapping the card/a chip
  /// rapidly, before that first `await` resolves, fires the handler again,
  /// and each independent call ends up pushing the AI route, stacking
  /// several copies of the chat screen. Shared across all four on purpose:
  /// they all navigate to the same destination, so a tap on one mid-flight
  /// while another is still resolving must be blocked too, not just repeats
  /// of the exact same one.
  bool _openingAi = false;

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

  Future<void> _openBellSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ComingSoonSheet.show(
      context,
      icon: LucideIcons.bell,
      message: l10n.homeNotificationsSheetMessage,
    );
  }

  /// HU-04: opens the fallback hero's month picker (no budget featured).
  /// [visibleMonth] seeds the sheet's initial year/selection; picking a
  /// month calls [HomeCubit.selectMonth] straight away, the sheet closes
  /// itself.
  Future<void> _openMonthPickerSheet(
    BuildContext context,
    DateTime visibleMonth,
  ) {
    final cubit = context.read<HomeCubit>();
    return MonthPickerSheet.show(
      context,
      initialMonth: visibleMonth,
      onMonthSelected: cubit.selectMonth,
    );
  }

  /// Awaits the detail page's navigation, then — if it deleted something —
  /// offers HU-05's "Deshacer" snackbar via [HomeCubit].
  Future<void> _openTransaction(BuildContext context, String id) async {
    final deletedId = await widget.onOpenTransaction(id);
    if (deletedId != null && context.mounted) {
      context.read<HomeCubit>().notifyExternalDelete(deletedId);
    }
  }

  /// Opens "Tu cuenta" — the avatar's tap (criterion 2).
  Future<void> _openAccountSheet(BuildContext context) {
    return AccountSheet.show(
      context,
      context.read<HomeCubit>(),
      onOpenSettings: widget.onOpenSettings,
      onSignOut: widget.onSignOut,
      onOpenSyncStatus: widget.onOpenSyncStatus,
      onActivateBackup: widget.onOpenLogin,
    );
  }

  /// Opens "Tu dinero" — the header's wallet button (criterion 3).
  Future<void> _openBalancesSheet(BuildContext context, HomeState state) {
    return BalancesSheet.show(
      context,
      accounts: state.accounts,
      onOpenAccountMovements: widget.onOpenAccountMovements,
      onAddAccount: widget.onAddAccount,
    );
  }

  /// The AI card's "Ayúdame a presupuestar" chip (`AiCardChips`, distinct from
  /// `HomeHeroCard`'s own "Crear presupuesto" CTA, which stays wired to
  /// [HomePage.onCreateBudget] unconditionally — that one is not AI-flavored).
  ///
  /// Dogfooding fix: with chat access, this chip is a strictly better
  /// starting point than the raw form — it opens a fresh conversation seeded
  /// with the budget question instead. [HomePage.onCreateBudget] (the direct
  /// nav to the new-budget form) stays as the fallback ONLY for the three
  /// cases where chat is not an option: no AI beta access, not paid/entitled,
  /// or no session — matching [AiCard]'s own contract that this chip never
  /// shows the beta-upsell sheet (Nivel 0 must never wall this off).
  Future<void> _onCreateBudgetOrAskAi(BuildContext context) async {
    if (_openingAi) {
      return;
    }
    _openingAi = true;
    try {
      final l10n = AppLocalizations.of(context);
      final hasAccess = await context.read<HomeCubit>().hasAiAccess();
      if (!context.mounted) {
        return;
      }
      if (hasAccess) {
        widget.onOpenAi(l10n.aiChatSuggestionBuildBudget);
      } else {
        widget.onCreateBudget();
      }
    } finally {
      _openingAi = false;
    }
  }

  /// Criterion 12: the chat gate check happens at the moment of the tap,
  /// never before. `question`, when present, seeds a brand-new thread and
  /// sends it right away (`AiAssistantPage.initialQuestion`).
  Future<void> _onAskQuestion(BuildContext context, String? question) async {
    if (_openingAi) {
      return;
    }
    _openingAi = true;
    try {
      final hasAccess = await context.read<HomeCubit>().hasAiAccess();
      if (!context.mounted) {
        return;
      }
      if (!hasAccess) {
        unawaited(AiBetaSheet.show(context));
        return;
      }
      widget.onOpenAi(question);
    } finally {
      _openingAi = false;
    }
  }

  /// The insight card's own "iniciar conversación" chip (bugfix item 7):
  /// same access gate as [_onAskQuestion], but routed through
  /// [HomePage.onOpenAiInsightQuestion] so the freshly created thread gets
  /// linked to the insight it came from.
  Future<void> _onStartInsightConversation(
    BuildContext context,
    String question,
  ) async {
    if (_openingAi) {
      return;
    }
    _openingAi = true;
    try {
      final cubit = context.read<HomeCubit>();
      final hasAccess = await cubit.hasAiAccess();
      if (!context.mounted) {
        return;
      }
      if (!hasAccess) {
        unawaited(AiBetaSheet.show(context));
        return;
      }
      await widget.onOpenAiInsightQuestion(
        question: question,
        insightType: cubit.state.aiInsight?.type.name,
      );
      // `cubit`, not `context.read<HomeCubit>()`: after this `await`,
      // `context` may no longer be mounted, and even when it is, `HomeCubit`
      // is a long-lived singleton — the reference captured above is still
      // valid either way, and skips the provider lookup entirely.
      cubit.refreshAiInsightConversation();
    } finally {
      _openingAi = false;
    }
  }

  /// The insight card's own "continuar conversación" chip: same access gate,
  /// but reopens [conversationId] directly instead of resuming whatever
  /// conversation is most recently active in general.
  Future<void> _onContinueInsightConversation(
    BuildContext context,
    String conversationId,
  ) async {
    if (_openingAi) {
      return;
    }
    _openingAi = true;
    try {
      final cubit = context.read<HomeCubit>();
      final hasAccess = await cubit.hasAiAccess();
      if (!context.mounted) {
        return;
      }
      if (!hasAccess) {
        unawaited(AiBetaSheet.show(context));
        return;
      }
      await widget.onOpenAiConversation(conversationId);
      cubit.refreshAiInsightConversation();
    } finally {
      _openingAi = false;
    }
  }

  /// HU-02 gated by `15-gate-cuenta.md`: without any active account the FAB
  /// (and the empty-state's own CTA, which reuses this) opens the bridge
  /// sheet instead of the movement form — the button itself always stays
  /// live and tappable, never disabled.
  Future<void> _addTransaction(BuildContext context) async {
    final canProceed = await showAccountGateIfNeeded(
      context,
      AccountGateSurface.movement,
    );
    if (canProceed) {
      widget.onAddTransaction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TutorialAutoShow(
      // `17-captura-voz.md` HU-02: press-and-hold is invisible, so it is
      // taught on the first visit to Inicio — and to everyone who was already
      // using the app before it existed, which needs no migration: a key that
      // was never recorded as seen simply is not seen. Its CTA does not just
      // explain the gesture, it performs it.
      tutorialKey: TutorialKey.voiceCaptureGesture,
      onCta: startVoiceCaptureFlow,
      child: Scaffold(
        floatingActionButton: AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          offset: _fabVisible ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _fabVisible ? 1 : 0,
            child: AppFab(
              icon: LucideIcons.plus,
              tooltip: l10n.transactionsAdd,
              onPressed: () => unawaited(_addTransaction(context)),
              // The primary voice trigger. Tap and hold are two different
              // actions on the same button, both of which end on the same
              // form — the hold only fills it in first.
              onLongPress: () => unawaited(startVoiceCaptureFlow(context)),
              longPressHint: l10n.captureVoiceFabLongPressHint,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<HomeCubit, HomeState>(
            listenWhen: (previous, current) =>
                previous.pendingUndoId != current.pendingUndoId &&
                current.pendingUndoId != null,
            listener: (context, state) {
              final cubit = context.read<HomeCubit>();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(l10n.transactionsUndoDeletedMessage),
                    action: SnackBarAction(
                      label: l10n.transactionsUndoAction,
                      onPressed: cubit.undoDelete,
                    ),
                    persist: false,
                  ),
                );
            },
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
                        onAvatarTap: () =>
                            unawaited(_openAccountSheet(context)),
                        onWalletTap: () =>
                            unawaited(_openBalancesSheet(context, state)),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      // Checks `spending == null` rather than `isLoading`: a
                      // failed first load (no snapshot yet) is not "loading"
                      // but still has no spending to show, and must fall back
                      // to the skeleton instead of a null-check crash.
                      child: state.spending == null
                          ? const HomeHeroSkeleton()
                          : HomeHeroCard(
                              heroState: state.heroState,
                              spending: state.spending!,
                              budgetProgress: state.budgetProgress,
                              // Only ever the fallback caption (criterion 5):
                              // `HomeHeroCard` ignores it once a budget is
                              // featured, in favor of the hero's own `Period
                              // Pill` label. Sourced from the snapshot's own
                              // `spending.month` (always "now"'s calendar
                              // month, per `HomeCubit.start`) rather than a
                              // direct clock read, so this stays deterministic
                              // and in sync with what `spending` itself counts.
                              monthLabel: _monthLabel(
                                context,
                                state.spending?.month ?? clock.now(),
                              ),
                              onCreateBudget: widget.onCreateBudget,
                              onOpenBudget: state.budgetProgress == null
                                  ? null
                                  : () => widget.onOpenBudget(
                                        state.budgetProgress!.budget.id,
                                      ),
                              onPreviousPeriod: () =>
                                  context.read<HomeCubit>().previousPeriod(),
                              onNextPeriod: () =>
                                  context.read<HomeCubit>().nextPeriod(),
                              onOpenMonthPicker: () => _openMonthPickerSheet(
                                context,
                                state.spending?.month ?? clock.now(),
                              ),
                            ),
                    ),
                  ),
                  // Card de IA (criterion 10/15): never in the empty state
                  // (nothing to summarize) nor as a loading skeleton — the
                  // slot stays empty until data has actually landed.
                  if (state.status == HomeStatus.ready && !state.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: AiCard(
                          insight: state.aiInsight,
                          budgetChipIsDirectNav: state.budgetChipIsDirectNav,
                          onAskQuestion: (question) =>
                              unawaited(_onAskQuestion(context, question)),
                          onCreateBudget: () =>
                              unawaited(_onCreateBudgetOrAskAi(context)),
                          onStartInsightConversation: (question) => unawaited(
                            _onStartInsightConversation(context, question),
                          ),
                          onContinueInsightConversation: (conversationId) =>
                              unawaited(
                            _onContinueInsightConversation(
                              context,
                              conversationId,
                            ),
                          ),
                          onDismissInsight: state.aiInsight == null
                              ? null
                              : () =>
                                  context.read<HomeCubit>().dismissAiInsight(),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
                        builder: (context, settings) => QuickAccessRow(
                          order: settings.quickAccessOrder,
                          pendingScheduledCount: state.pendingScheduledCount,
                          onOpenScheduledPayments:
                              widget.onOpenScheduledPayments,
                          onOpenAccounts: widget.onOpenAccounts,
                          onOpenDebts: widget.onOpenDebts,
                          onOpenReports: widget.onOpenReports,
                          onOpenGoals: widget.onOpenGoals,
                          onCustomize: widget.onOpenQuickAccessOrder,
                        ),
                      ),
                    ),
                  ),
                  // Pencil (`AmifS`/`Y5TnWd`, `DliNF`/`dJDHi`) goes straight
                  // from "Acceso rápido" to the loading/empty state: the
                  // "Movimientos recientes" header only exists once there is
                  // something to head.
                  if (state.status == HomeStatus.ready && !state.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                        child: RecentActivityHeader(
                          onSeeAll: widget.onSeeAllTransactions,
                          showSeeAll: true,
                        ),
                      ),
                    ),
                  ..._bodySlivers(context, state),
                ],
              );
            },
          ),
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
              child: HomeMovementsEmptyState(
                onAdd: () => unawaited(_addTransaction(context)),
              ),
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
                    onTap: () =>
                        _openTransaction(context, entry.transaction.id),
                  ),
              ],
            ),
          ),
          // Pencil's spacer below Movimientos is `height:fill_container`
          // (`docs`/`pages/inicio.md` § "Carril del FAB"): it must grow to
          // at least fill whatever viewport space is left, not just reserve
          // a fixed 96px — a fixed `SizedBox` inside the list only
          // guarantees that gap when the content already overflows the
          // viewport. With a short list (few recent movements) the content
          // falls short of the screen and the FAB, docked at a fixed
          // bottom-right position, ends up floating directly over the last
          // row instead of the empty space below it. `SliverFillRemaining`
          // guarantees at least the remaining viewport height while still
          // respecting the 96px floor when content is already long enough
          // to scroll.
          const SliverFillRemaining(
            hasScrollBody: false,
            child: SizedBox(height: 96),
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
/// with a CTA that opens the new-transaction form. No AI card here.
class HomeMovementsEmptyState extends StatelessWidget {
  const HomeMovementsEmptyState({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The extra top/bottom inset is the only thing home adds: it sits in a
    // fixed slot between the hero and the tab bar.
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      child: EmptyState(
        icon: LucideIcons.receipt,
        message: l10n.homeEmptyMovements,
        ctaLabel: l10n.transactionsAdd,
        onCta: onAdd,
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
