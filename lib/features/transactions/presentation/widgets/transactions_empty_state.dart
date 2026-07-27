import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/widgets/empty_state.dart';

/// The transaction list's empty state (HU-06/HU-06b): neutral, never an
/// error — an unfiltered empty account and a filtered/searched period with no
/// matches both land here, only the [message] differs.
///
/// Only the icon and the copy are feature-specific; the layout is the shared
/// `Empty State` component (`jmQO5`).
class TransactionsEmptyState extends StatelessWidget {
  const TransactionsEmptyState({
    required this.message,
    this.ctaLabel,
    this.onCta,
    super.key,
  });

  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: LucideIcons.receipt,
        message: message,
        ctaLabel: ctaLabel,
        onCta: onCta,
      );
}
