import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../cubit/delete_account_cubit.dart';
import '../cubit/delete_account_state.dart';
import 'sheets/confirm_delete_account_sheet.dart';
import 'sheets/local_data_choice_sheet.dart';

/// Orchestrates HU-07's 3-step flow, starting from "Eliminar cuenta" in
/// Ajustes: paso 1 and paso 2 are Bottom Sheets (`j8ZdEx`/`K8SAG`), paso 3
/// (`sqm4I`) is a full page reached via `onFinished`.
///
/// Each sheet closes itself once `DeleteAccountCubit` advances; this only
/// has to look at the cubit's state after each sheet closes to decide
/// whether to show the next one or stop (the user cancelled).
class DeleteAccountFlow {
  const DeleteAccountFlow._();

  static Future<void> start(
    BuildContext context, {
    required VoidCallback onFinished,
  }) async {
    final cubit = getIt<DeleteAccountCubit>();

    await ConfirmDeleteAccountSheet.show(context, cubit);
    if (cubit.state.step != DeleteAccountStep.localDataChoice) {
      return; // user cancelled paso 1
    }

    if (!context.mounted) {
      return;
    }
    await LocalDataChoiceSheet.show(context, cubit);
    if (cubit.state.step != DeleteAccountStep.done) {
      return; // still choosing / failed wiping local data
    }

    onFinished();
  }
}
