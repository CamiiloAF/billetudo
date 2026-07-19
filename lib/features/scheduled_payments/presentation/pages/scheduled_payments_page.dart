import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/scheduled_payments_list_cubit.dart';
import '../cubit/scheduled_payments_list_state.dart';
import '../widgets/pending_occurrences_section.dart';
import '../widgets/scheduled_card.dart';
import '../widgets/scheduled_count_pill.dart';

/// The "próximos vencimientos" list (HU-04): active templates ordered by
/// `nextDate` ascending, with an "Activos · N" / "Terminados · N" counter
/// pair and a "Pendientes" card shortcut to "Por confirmar" for manual-mode
/// occurrences already due.
class ScheduledPaymentsPage extends StatelessWidget {
  const ScheduledPaymentsPage({
    required this.onAddScheduledPayment,
    required this.onOpenScheduledPayment,
    required this.onOpenPending,
    required this.onOpenFinished,
    super.key,
  });

  final VoidCallback onAddScheduledPayment;
  final ValueChanged<String> onOpenScheduledPayment;
  final VoidCallback onOpenPending;
  final VoidCallback onOpenFinished;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduledPaymentsTitle)),
      floatingActionButton: FloatingActionButton(
        // ignore: avoid_hardcoded_ui_strings
        heroTag: 'scheduledPaymentsAddFab',
        onPressed: onAddScheduledPayment,
        tooltip: l10n.scheduledPaymentsAdd,
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child:
            BlocBuilder<ScheduledPaymentsListCubit, ScheduledPaymentsListState>(
          builder: (context, state) => switch (state.status) {
            ScheduledPaymentsListStatus.loading =>
              const ScheduledPaymentsLoadingView(),
            ScheduledPaymentsListStatus.failure => ScheduledPaymentsErrorView(
                onRetry: context.read<ScheduledPaymentsListCubit>().start,
              ),
            ScheduledPaymentsListStatus.ready when state.items.isEmpty =>
              ScheduledPaymentsEmptyView(onAdd: onAddScheduledPayment),
            ScheduledPaymentsListStatus.ready => ScheduledPaymentsListView(
                state: state,
                onOpenScheduledPayment: onOpenScheduledPayment,
                onOpenPending: onOpenPending,
                onOpenFinished: onOpenFinished,
              ),
          },
        ),
      ),
    );
  }
}

class ScheduledPaymentsLoadingView extends StatelessWidget {
  const ScheduledPaymentsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).scheduledPaymentsLoading,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class ScheduledPaymentsEmptyView extends StatelessWidget {
  const ScheduledPaymentsEmptyView({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
              child: Icon(LucideIcons.repeat,
                  size: 40, color: colors.primaryOnSoft),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.scheduledPaymentsEmptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.scheduledPaymentsAdd),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduledPaymentsErrorView extends StatelessWidget {
  const ScheduledPaymentsErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  LucideIcons.triangleAlert,
                  color: colors.textSecondary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.scheduledPaymentsErrorTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.scheduledPaymentsErrorLocalFirst,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
            ],
          ),
        ),
      ),
    );
  }
}

class ScheduledPaymentsListView extends StatelessWidget {
  const ScheduledPaymentsListView({
    required this.state,
    required this.onOpenScheduledPayment,
    required this.onOpenPending,
    required this.onOpenFinished,
    super.key,
  });

  final ScheduledPaymentsListState state;
  final ValueChanged<String> onOpenScheduledPayment;
  final VoidCallback onOpenPending;
  final VoidCallback onOpenFinished;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            ScheduledCountPill(
              label: l10n.scheduledPaymentsActiveCount(state.activeCount),
              emphasized: true,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onOpenFinished,
              child: ScheduledCountPill(
                label: l10n.scheduledFinishedCount(state.finishedCount),
                emphasized: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PendingOccurrencesSection(onOpenPending: onOpenPending),
        for (final entry in state.items) ...[
          ScheduledCard(
            entry: entry,
            onTap: () => onOpenScheduledPayment(entry.scheduledPayment.id),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
