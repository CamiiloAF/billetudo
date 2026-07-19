import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../accounts/presentation/widgets/empty_state.dart';
import '../cubit/finished_scheduled_payments_cubit.dart';
import '../cubit/finished_scheduled_payments_state.dart';
import '../widgets/scheduled_card.dart';
import 'scheduled_payments_page.dart' show ScheduledPaymentsErrorView;

/// The finished-templates history ("Terminados", HU-04 overflow): reached
/// from the "próximos vencimientos" list's neutral pill, análogo al
/// histórico de Presupuestos (`ArchivedBudgetsPage`).
class FinishedScheduledPaymentsPage extends StatelessWidget {
  const FinishedScheduledPaymentsPage({
    required this.onOpenScheduledPayment,
    super.key,
  });

  final ValueChanged<String> onOpenScheduledPayment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduledFinishedTitle)),
      body: SafeArea(
        child: BlocBuilder<FinishedScheduledPaymentsCubit,
            FinishedScheduledPaymentsState>(
          builder: (context, state) => switch (state.status) {
            FinishedScheduledPaymentsStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            FinishedScheduledPaymentsStatus.failure =>
              ScheduledPaymentsErrorView(
                onRetry: context.read<FinishedScheduledPaymentsCubit>().start,
              ),
            FinishedScheduledPaymentsStatus.ready when state.items.isEmpty =>
              EmptyState(
                icon: LucideIcons.calendarCheck2,
                message: l10n.scheduledFinishedEmpty,
              ),
            FinishedScheduledPaymentsStatus.ready =>
              FinishedScheduledPaymentsListView(
                state: state,
                onOpenScheduledPayment: onOpenScheduledPayment,
              ),
          },
        ),
      ),
    );
  }
}

class FinishedScheduledPaymentsListView extends StatelessWidget {
  const FinishedScheduledPaymentsListView({
    required this.state,
    required this.onOpenScheduledPayment,
    super.key,
  });

  final FinishedScheduledPaymentsState state;
  final ValueChanged<String> onOpenScheduledPayment;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: state.items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = state.items[index];
        return ScheduledCard(
          entry: entry,
          onTap: () => onOpenScheduledPayment(entry.scheduledPayment.id),
        );
      },
    );
  }
}
