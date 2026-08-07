import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_fab.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../../../core/widgets/root_tab_header.dart';
import '../../../accounts/presentation/utils/show_account_gate_if_needed.dart';
import '../../../accounts/presentation/widgets/account_gate_copy.dart';
import '../../../transactions/presentation/widgets/transaction_header_button.dart';
import '../../../tutorials/domain/entities/tutorial_key.dart';
import '../../../tutorials/presentation/widgets/tutorial_auto_show.dart';
import '../cubit/scheduled_payments_list_cubit.dart';
import '../cubit/scheduled_payments_list_state.dart';
import '../widgets/scheduled_finished_filter_view.dart';
import '../widgets/scheduled_payments_empty_view.dart';
import '../widgets/scheduled_payments_error_view.dart';
import '../widgets/scheduled_payments_list_view.dart';
import '../widgets/scheduled_payments_loading_view.dart';
import '../widgets/scheduled_payments_no_active_view.dart';
import '../widgets/sheets/scheduled_payments_menu_sheet.dart';

/// The "próximos vencimientos" list (HU-04): active templates ordered by
/// `nextDate` ascending, with an "Activos · N" / "Terminados · N" chip pair
/// and a "Pendientes" card shortcut to "Por confirmar" for manual-mode
/// occurrences already due.
///
/// "Terminados" is a **filter of this list**, not a screen of its own: the
/// chips look like a filter, so they behave like one. Header, chips, FAB and
/// tab bar stay put; only the content area swaps.
class ScheduledPaymentsPage extends StatelessWidget {
  const ScheduledPaymentsPage({
    required this.onAddScheduledPayment,
    required this.onOpenScheduledPayment,
    required this.onOpenPending,
    this.showBackButton = true,
    super.key,
  });

  final VoidCallback onAddScheduledPayment;
  final ValueChanged<String> onOpenScheduledPayment;
  final VoidCallback onOpenPending;

  /// Whether to render the stacked-screen `Page Header` with an `arrow-left`
  /// back button. As a bottom-nav tab root (bugfix item 7) there is nothing to
  /// pop to, so the router passes `false` and the page uses the left-aligned
  /// [RootTabHeader] shared by the other tab roots instead.
  final bool showBackButton;

  /// HU-01 gated by `15-gate-cuenta.md`: `ScheduledPayments.accountId` is
  /// NOT NULL, so without any active account this opens the bridge sheet
  /// instead of a form that could never save.
  Future<void> _addScheduledPayment(BuildContext context) async {
    final canProceed = await showAccountGateIfNeeded(
      context,
      AccountGateSurface.scheduledPayment,
    );
    if (canProceed) {
      onAddScheduledPayment();
    }
  }

  Future<void> _openMenu(BuildContext context) async {
    final action = await ScheduledPaymentsMenuSheet.show(context);
    if (action == null || !context.mounted) {
      return;
    }
    switch (action) {
      case ScheduledPaymentsMenuAction.viewHelp:
        await reopenTutorial(
          context,
          TutorialKey.scheduledPaymentsScreen,
          onCta: (context) => unawaited(_addScheduledPayment(context)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final Widget content =
        BlocBuilder<ScheduledPaymentsListCubit, ScheduledPaymentsListState>(
      builder: (context, state) {
        final cubit = context.read<ScheduledPaymentsListCubit>();
        if (state.showsFinished) {
          return ScheduledFinishedFilterView(
            state: state,
            onOpenScheduledPayment: onOpenScheduledPayment,
            onFilterSelected: cubit.showFilter,
            onRetry: cubit.start,
          );
        }
        return switch (state.status) {
          // The counters are unknown here, so the chips row is replaced by
          // a placeholder that reserves its height instead of letting it
          // pop in and push the content down.
          ScheduledPaymentsListStatus.loading =>
            const ScheduledPaymentsLoadingView(
              showsChipsPlaceholder: true,
            ),
          // `KeKke` `Content`: padding [6, 20, 20, 20] — a terminal state
          // with no chips and no list, so it does not reserve the FAB's
          // 92px the way the loaded states do.
          ScheduledPaymentsListStatus.failure => Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 20),
              child: ScheduledPaymentsErrorView(onRetry: cubit.start),
            ),
          // 0 activas + N terminadas keeps the chips (`U9jUDR`); with
          // nothing at all there is no filter to offer (`YI1wY`).
          ScheduledPaymentsListStatus.ready
              when state.items.isEmpty && state.finishedCount > 0 =>
            ScheduledPaymentsNoActiveView(
              state: state,
              onAdd: () => unawaited(_addScheduledPayment(context)),
              onFilterSelected: cubit.showFilter,
            ),
          ScheduledPaymentsListStatus.ready when state.items.isEmpty =>
            ScheduledPaymentsEmptyView(
              onAdd: () => unawaited(_addScheduledPayment(context)),
            ),
          ScheduledPaymentsListStatus.ready => ScheduledPaymentsListView(
              state: state,
              onOpenScheduledPayment: onOpenScheduledPayment,
              onOpenPending: onOpenPending,
              onFilterSelected: cubit.showFilter,
            ),
        };
      },
    );

    final Widget body = showBackButton
        ? content
        : Column(
            children: [
              RootTabHeader(
                title: l10n.scheduledPaymentsTitle,
                // Was an empty `Action Spacer`: the tab root now carries the
                // same `⋮` "Ver ayuda" affordance as the other 3 HU-01
                // screens (criterion 6).
                actions: [
                  PageHeaderCircleButton(
                    icon: LucideIcons.ellipsisVertical,
                    background: colors.muted,
                    foreground: colors.textPrimary,
                    tooltip: l10n.scheduledPaymentsMenuTooltip,
                    iconSize: 20,
                    onPressed: () => unawaited(_openMenu(context)),
                  ),
                ],
              ),
              Expanded(child: content),
            ],
          );

    return TutorialAutoShow(
      tutorialKey: TutorialKey.scheduledPaymentsScreen,
      onCta: (context) => unawaited(_addScheduledPayment(context)),
      child: Scaffold(
      appBar: showBackButton
          ? AppBar(
              // `Dtm0X`: the back affordance is an `arrow-left` inside a
              // `$muted` circle, not the platform default chevron.
              leadingWidth: 60,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: TransactionHeaderButton(
                  icon: LucideIcons.arrowLeft,
                  background: colors.muted,
                  foreground: colors.textPrimary,
                  tooltip: l10n.commonBack,
                  onPressed: Navigator.of(context).pop,
                ),
              ),
              title: Text(l10n.scheduledPaymentsTitle),
            )
          : null,
      floatingActionButton: AppFab(
        icon: LucideIcons.plus,
        tooltip: l10n.scheduledPaymentsAdd,
        onPressed: () => unawaited(_addScheduledPayment(context)),
      ),
      body: SafeArea(child: body),
      ),
    );
  }
}
