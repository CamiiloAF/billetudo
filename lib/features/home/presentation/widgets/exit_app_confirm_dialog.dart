import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';

/// Confirms leaving the app when the user gestures back from the Inicio
/// branch's root. No dedicated Pencil design exists for this dialog; it
/// follows the plain `AlertDialog` pattern already used elsewhere (see
/// `ConfirmDeleteRootWithSubcategoriesSheet._confirmCascade`).
class ExitAppConfirmDialog extends StatelessWidget {
  const ExitAppConfirmDialog({super.key});

  /// Shows the dialog and resolves to `true` if the user confirmed leaving
  /// the app, `false` or `null` otherwise.
  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (context) => const ExitAppConfirmDialog(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.homeExitConfirmTitle),
      content: Text(l10n.homeExitConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.homeExitConfirmAction),
        ),
      ],
    );
  }
}
