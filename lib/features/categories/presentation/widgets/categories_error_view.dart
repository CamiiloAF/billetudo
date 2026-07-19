import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/error_state.dart';

/// The categories list error state (`oaBzm`).
///
/// Only the headline is feature-specific; the card itself is the shared
/// `Error State` component (`ECG7D`).
class CategoriesErrorView extends StatelessWidget {
  const CategoriesErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ErrorState(
      title: l10n.categoriesErrorTitle,
      description: l10n.accountsErrorLocalFirst,
      onRetry: onRetry,
    );
  }
}
