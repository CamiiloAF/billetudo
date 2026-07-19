import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/empty_state.dart';

/// The total empty state (`YI1wY`): no templates at all, active or finished.
///
/// Deliberately without the filter chips — there is no other slice to switch
/// to, and a lone "Activos · 0" pill would be scaffolding around nothing.
class ScheduledPaymentsEmptyView extends StatelessWidget {
  const ScheduledPaymentsEmptyView({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      // `YI1wY` `Content`: padding [6, 20, 20, 20], centred.
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 20),
      child: EmptyState(
        icon: LucideIcons.calendarClock,
        message: l10n.scheduledPaymentsEmptyMessage,
        ctaLabel: l10n.scheduledPaymentsEmptyCta,
        onCta: onAdd,
      ),
    );
  }
}
