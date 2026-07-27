import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/error_state.dart';

/// The accounts list error state (`L6Za0`).
///
/// Only the headline is feature-specific; the card itself is the shared
/// `Error State` component (`ECG7D`).
class AccountsErrorView extends StatelessWidget {
  const AccountsErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ErrorState(
      title: l10n.accountsErrorTitle,
      description: l10n.accountsErrorLocalFirst,
      onRetry: onRetry,
    );
  }
}
