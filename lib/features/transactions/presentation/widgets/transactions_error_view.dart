import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/error_state.dart';

/// The transaction list error state, neutral tone: a failed read is not a
/// financial alarm, and the data is still on the device.
///
/// Only the headline is feature-specific; the card itself is the shared
/// `Error State` component (`ECG7D`).
class TransactionsErrorView extends StatelessWidget {
  const TransactionsErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ErrorState(
      title: l10n.transactionsErrorTitle,
      description: l10n.transactionsErrorLocalFirst,
      onRetry: onRetry,
    );
  }
}
