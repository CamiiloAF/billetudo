import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_draft.dart';
import '../repositories/pending_capture_repository.dart';
import 'learn_merchant_category.dart';

/// Registers a capture as a real movement (HU-05).
///
/// Confirming is never blind: the caller reaches this point from the same
/// transaction form the rest of the app uses, pre-filled with what was
/// extracted, and `draft` is whatever the user saw and accepted — including
/// their edits. The draft goes through the very same validation as a manual
/// transaction, so a capture cannot register a movement the form would have
/// rejected (a category is still mandatory for income/expense).
///
/// `TransactionDraft.source` is forced to `notification` and the id is
/// cleared: this always creates a movement, never edits one, and the origin
/// is a historical fact the user cannot rewrite afterwards.
///
/// The confirmation also feeds the learning of HU-06 — the user just told the
/// app which category this merchant belongs to. Learning is best-effort: if
/// it fails, the transaction is already created and reporting an error would
/// be lying about what happened.
@injectable
class ConfirmPendingCapture {
  const ConfirmPendingCapture(this._repository, this._learn);

  final PendingCaptureRepository _repository;
  final LearnMerchantCategory _learn;

  FutureResult<Transaction> call({
    required String captureId,
    required TransactionDraft draft,
  }) async {
    final captureResult = await _repository.getCapture(captureId);
    final String? merchantRaw;
    switch (captureResult) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final capture):
        merchantRaw = capture.merchantRaw;
    }

    final validated = TransactionDraft(
      accountId: draft.accountId,
      categoryId: draft.categoryId,
      categoryKind: draft.categoryKind,
      amountMinor: draft.amountMinor,
      currency: draft.currency,
      type: draft.type,
      date: draft.date,
      note: draft.note,
      source: TransactionSource.notification,
      transferAccountId: draft.transferAccountId,
      goalId: draft.goalId,
      debtId: draft.debtId,
      countsInBudget: draft.countsInBudget,
    ).validated();
    final TransactionDraft normalized;
    switch (validated) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final value):
        normalized = value;
    }

    final created = await _repository.confirmCapture(
      captureId: captureId,
      draft: normalized,
    );
    if (created case Left()) {
      return created;
    }

    await _learn(merchantRaw: merchantRaw, categoryId: normalized.categoryId);
    return created;
  }
}
