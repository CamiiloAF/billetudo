import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/error_state.dart';

/// The list's error state (`KeKke`/`w3MUo`): local-first copy plus a retry —
/// the data never left the device, so the message never suggests it was lost.
///
/// Only the headline is feature-specific; the card itself is the shared
/// `Error State` component (`ECG7D`).
class ScheduledPaymentsErrorView extends StatelessWidget {
  const ScheduledPaymentsErrorView({
    required this.onRetry,
    this.title,
    super.key,
  });

  final VoidCallback onRetry;

  /// The headline. `KeKke` and `w3MUo` share the card but not this line: the
  /// initial error names "tus pagos programados", the one inside the
  /// "Terminados" filter names "tus pagos terminados" — it failed to load the
  /// filtered list, not the whole feature. Defaults to the former.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ErrorState(
      title: title ?? l10n.scheduledPaymentsErrorTitle,
      description: l10n.scheduledPaymentsErrorLocalFirst,
      onRetry: onRetry,
    );
  }
}
