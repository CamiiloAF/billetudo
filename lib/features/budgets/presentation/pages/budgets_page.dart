import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../../settings/presentation/cubit/app_settings_cubit.dart';
import '../../../settings/presentation/widgets/sheets/envelope_info_sheet.dart';
import '../../domain/entities/zero_based_summary.dart';
import '../cubit/budgets_list_cubit.dart';
import '../cubit/budgets_list_state.dart';
import '../cubit/zero_based_summary_cubit.dart';
import '../widgets/budget_line.dart';
import '../widgets/budget_skeleton_row.dart';
import '../widgets/budgets_error_view.dart';
import '../widgets/envelope_hero.dart';
import '../widgets/sheets/budgets_menu_sheet.dart';

/// The budgets list (`s833Gk`). Custom header ("Presupuestos" + `+`) over the
/// app tab bar; no `Page Header`. The overflow menu reaches the history.
class BudgetsPage extends StatelessWidget {
  const BudgetsPage({
    required this.onAddBudget,
    required this.onOpenBudget,
    required this.onOpenHistory,
    super.key,
  });

  final VoidCallback onAddBudget;
  final ValueChanged<String> onOpenBudget;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final envelopeEnabled =
        context.watch<AppSettingsCubit>().state.zeroBasedEnabled;
    final ZeroBasedSummary? summary = envelopeEnabled
        ? context.watch<ZeroBasedSummaryCubit>().state.summary
        : null;
    final Widget? envelopeHeader = summary == null
        ? null
        : EnvelopeHero(
            summary: summary,
            onInfo: () => unawaited(EnvelopeInfoSheet.show(context)),
          );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BudgetsPageHeader(
              onAddBudget: onAddBudget,
              onOpenHistory: onOpenHistory,
              envelopeEnabled: envelopeEnabled,
            ),
            Expanded(
              child: BlocBuilder<BudgetsListCubit, BudgetsListState>(
                builder: (context, state) => switch (state.status) {
                  BudgetsListStatus.loading => const BudgetsLoadingView(),
                  BudgetsListStatus.failure => BudgetsErrorView(
                      onRetry: context.read<BudgetsListCubit>().start,
                    ),
                  BudgetsListStatus.ready when state.budgets.isEmpty =>
                    BudgetsEmptyView(
                      onAddBudget: onAddBudget,
                      header: envelopeHeader,
                    ),
                  BudgetsListStatus.ready => BudgetsListView(
                      state: state,
                      onOpenBudget: onOpenBudget,
                      onAddBudget: onAddBudget,
                      header: envelopeHeader,
                      envelopeMode: envelopeEnabled,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The list's own header (`s833Gk`): title left-aligned ("Presupuestos" +
/// `700`/24px), unlike the shared `PageHeader` (which is for detail/form
/// screens with a back button) — this is the root of the tab, so the global
/// `AppBarTheme.centerTitle` never applies here.
class BudgetsPageHeader extends StatelessWidget {
  const BudgetsPageHeader({
    required this.onAddBudget,
    required this.onOpenHistory,
    required this.envelopeEnabled,
    super.key,
  });

  final VoidCallback onAddBudget;
  final VoidCallback onOpenHistory;
  final bool envelopeEnabled;

  Future<void> _openMenu(BuildContext context) async {
    final settings = context.read<AppSettingsCubit>();
    final action = await BudgetsMenuSheet.show(
      context,
      envelopeEnabled: envelopeEnabled,
    );
    if (action == null || !context.mounted) {
      return;
    }
    switch (action) {
      case BudgetsMenuAction.history:
        onOpenHistory();
      case BudgetsMenuAction.toggleEnvelope:
        await settings.setZeroBasedEnabled(!envelopeEnabled);
      case BudgetsMenuAction.envelopeInfo:
        if (context.mounted) {
          await EnvelopeInfoSheet.show(context);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.budgetsTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
          ),
          // `ymsmU` orders the two 44pt circles ⋮ then + — the overflow is
          // the secondary action, so the filled `$primary` one sits last,
          // closest to the screen edge. The overflow opens the sheet
          // `TmOGV`/`tFZyK`, never a Material popup menu.
          PageHeaderCircleButton(
            icon: LucideIcons.ellipsisVertical,
            background: colors.muted,
            foreground: colors.textPrimary,
            tooltip: l10n.budgetsMenuTooltip,
            iconSize: 20,
            onPressed: () => unawaited(_openMenu(context)),
          ),
          const SizedBox(width: 8),
          PageHeaderCircleButton(
            icon: LucideIcons.plus,
            background: colors.primary,
            foreground: colors.onPrimary,
            tooltip: l10n.budgetsAdd,
            iconSize: 20,
            onPressed: onAddBudget,
          ),
        ],
      ),
    );
  }
}

/// Loading: four skeleton rows matching the real row geometry.
class BudgetsLoadingView extends StatelessWidget {
  const BudgetsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).budgetsLoading,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(height: 18),
        itemBuilder: (context, index) => const BudgetSkeletonRow(),
      ),
    );
  }
}

class BudgetsEmptyView extends StatelessWidget {
  const BudgetsEmptyView({required this.onAddBudget, this.header, super.key});

  final VoidCallback onAddBudget;

  /// The "Modo sobres" hero, when active (HU-06).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = EmptyState(
      icon: LucideIcons.wallet,
      message: l10n.budgetsEmptyMessage,
      description: l10n.budgetsEmptyDescription,
      // `bzHnz`: title + invite read as one block, 6pt apart.
      descriptionSpacing: 6,
      ctaLabel: l10n.budgetsEmptyCta,
      onCta: onAddBudget,
    );
    final header = this.header;
    if (header == null) {
      return empty;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        header,
        const SizedBox(height: 20),
        empty,
      ],
    );
  }
}

/// The list with data: budget lines followed by the "+ Nuevo presupuesto"
/// CTA row (replaces the FAB on this screen).
class BudgetsListView extends StatelessWidget {
  const BudgetsListView({
    required this.state,
    required this.onOpenBudget,
    required this.onAddBudget,
    this.header,
    this.envelopeMode = false,
    super.key,
  });

  final BudgetsListState state;
  final ValueChanged<String> onOpenBudget;
  final VoidCallback onAddBudget;

  /// The "Modo sobres" hero, when active (HU-06). Rendered as the first item.
  final Widget? header;

  /// In "Modo sobres" the rows read "Asignado" and the list is denser
  /// (`D1G5hl`: card padding 16, gap 12 vs. the normal list's 18/18).
  final bool envelopeMode;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final headerCount = header == null ? 0 : 1;
    // `D1G5hl` closes the envelope list with the last envelope: the "+" of
    // the header is the only entry point there, so the CTA row does not
    // repeat it.
    final ctaCount = envelopeMode ? 0 : 1;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: headerCount + state.budgets.length + ctaCount,
      separatorBuilder: (context, index) =>
          SizedBox(height: envelopeMode ? 12 : 18),
      itemBuilder: (context, index) {
        if (header != null && index == 0) {
          return header;
        }
        final budgetIndex = index - headerCount;
        if (budgetIndex == state.budgets.length) {
          return NewBudgetCta(onTap: onAddBudget);
        }
        final entry = state.budgets[budgetIndex];
        return BudgetLine(
          entry: entry,
          envelopeMode: envelopeMode,
          onTap: () => onOpenBudget(entry.budget.id),
        );
      },
    );
  }
}

/// The "+ Nuevo presupuesto" CTA row at the end of the list.
class NewBudgetCta extends StatelessWidget {
  const NewBudgetCta({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: colors.primaryLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  Icon(LucideIcons.plus, size: 20, color: colors.primaryOnSoft),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.budgetsAdd,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.primaryOnSoftStrong,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
