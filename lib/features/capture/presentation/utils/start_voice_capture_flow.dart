import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../accounts/presentation/utils/show_account_gate_if_needed.dart';
import '../../../accounts/presentation/widgets/account_gate_copy.dart';
import '../../domain/entities/spoken_transaction_draft.dart';
import '../widgets/voice_capture_sheet.dart';

/// The primary trigger's whole flow: account gate -> dictation sheet ->
/// prefilled form.
///
/// The account gate comes first and *continues on its own*
/// (`15-gate-cuenta.md`): the trigger is never greyed out for lack of an
/// account — it offers to create one and, once created, carries straight on
/// into the dictation instead of dropping the user where they started.
///
/// The route is the same new-movement form the manual path uses. The voice
/// only prefills it; the user confirms and saves there, and nothing is
/// written before that (HU-01).
Future<void> startVoiceCaptureFlow(BuildContext context) async {
  final canProceed = await showAccountGateIfNeeded(
    context,
    AccountGateSurface.movement,
  );
  if (!canProceed || !context.mounted) {
    return;
  }
  final draft = await VoiceCaptureSheet.show(context);
  if (draft == null || !context.mounted) {
    return;
  }
  await context.push<void>(routeForDraft(draft));
}

/// The route a [draft] should open.
///
/// A draft that carries nothing at all — the "Escribir a mano" exit of the
/// permission explainer, where the user never got to say a word — opens the
/// plain manual form. Stamping that one as `source: voice` would record a
/// capture origin that never happened, and the source is a historical fact,
/// not a description of how the form was reached.
String routeForDraft(SpokenTransactionDraft draft) {
  if (draft.isEmpty && draft.transcript.trim().isEmpty) {
    return AppRoutes.newTransaction;
  }
  return AppRoutes.newTransactionFromVoice(
    amountMinor: draft.amountMinor,
    amountIsUncertain: draft.amountIsUncertain,
    type: draft.type?.name,
    accountId: draft.accountId,
    categoryId: draft.categoryId,
    categoryKind: draft.categoryKind?.name,
    categoryName: draft.categoryName,
    date: draft.date,
    note: draft.note,
  );
}
