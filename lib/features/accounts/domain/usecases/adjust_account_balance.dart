import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_draft.dart';
import '../../../transactions/domain/usecases/create_transaction.dart';
import '../entities/account.dart';
import '../entities/account_balance_adjustment.dart';
import '../entities/account_draft.dart';
import 'update_account.dart';

/// Mejora #1: reconciles an account's balance to a figure the user names,
/// either by registering a movement for the difference or by correcting the
/// opening balance.
///
/// Architecture note: the "registrar ajuste" path crosses into the
/// Transactions feature. It does so through that feature's own **domain** use
/// case ([CreateTransaction]), never its repository or data layer, so the
/// dependency stays domain → domain and the layering rule holds. The
/// "corregir saldo inicial" path stays inside Accounts via [UpdateAccount].
///
/// All sign handling lives in [AccountBalanceAdjustment]; this use case only
/// picks which write to perform.
@injectable
class AdjustAccountBalance {
  const AdjustAccountBalance(this._createTransaction, this._updateAccount);

  /// The "Otros" buckets a registered adjustment lands in, by money direction.
  /// These ids come from the shared `category_seeds` catalog (Supabase) and are
  /// reused 1:1 as the local category id, so the adjustment always resolves to
  /// a real seeded row ("Otros ingresos"/"Otros gastos").
  static const String otherIncomeCategoryId = 'seed-other-income';
  static const String otherExpenseCategoryId = 'seed-other-expenses';

  final CreateTransaction _createTransaction;
  final UpdateAccount _updateAccount;

  FutureResult<Unit> call({
    required Account account,
    required int currentBalanceMinor,
    required int newDisplayedBalanceMinor,
    required BalanceAdjustmentMode mode,
    String? note,
    DateTime? now,
  }) async {
    final adjustment = AccountBalanceAdjustment.from(
      account: account,
      currentBalanceMinor: currentBalanceMinor,
      newDisplayedBalanceMinor: newDisplayedBalanceMinor,
    );

    // No difference is a no-op success: the balance is already what the user
    // asked for, so there is nothing to write.
    if (!adjustment.hasChange) {
      return const Right(unit);
    }

    switch (mode) {
      case BalanceAdjustmentMode.registerMovement:
        final isIncome = adjustment.isIncome;
        final draft = TransactionDraft(
          accountId: account.id,
          amountMinor: adjustment.diffMinor.abs(),
          currency: account.currency,
          type: isIncome ? TransactionType.income : TransactionType.expense,
          date: now ?? DateTime.now(),
          note: note,
          // Categorized in the matching "Otros" bucket by direction, so the
          // adjustment shows up in reports/budgets under a real category.
          categoryId: isIncome ? otherIncomeCategoryId : otherExpenseCategoryId,
          categoryKind: isIncome ? CategoryKind.income : CategoryKind.expense,
          // `source` defaults to `TransactionSource.manual`.
          // Defensive fallback only: with the category set above the draft
          // already passes the mandatory-category rule the normal way; this
          // keeps the adjustment valid even in the edge case where, for some
          // reason, the category could not be attached.
          isBalanceAdjustment: true,
        );
        final result = await _createTransaction(draft);
        return result.map((_) => unit);

      case BalanceAdjustmentMode.correctInitial:
        final draft = _draftFrom(account, adjustment.newInitialBalanceMinor);
        // Type and currency are unchanged, so `UpdateAccount` never asks for
        // confirmation here; passing `confirmed` keeps that explicit.
        final result = await _updateAccount(draft, confirmed: true);
        return result.map((_) => unit);
    }
  }

  /// Rebuilds the account's draft with only the opening balance changed.
  /// `numberEdit` is left at its default (keep the stored number): this write
  /// never touches secure storage.
  AccountDraft _draftFrom(Account account, int newInitialBalanceMinor) =>
      AccountDraft(
        id: account.id,
        name: account.name,
        type: account.type,
        currency: account.currency,
        initialBalanceMinor: newInitialBalanceMinor,
        institution: account.institution,
        last4: account.last4,
        interestRateBps: account.interestRateBps,
        creditLimitMinor: account.creditLimitMinor,
        statementDay: account.statementDay,
        paymentDueDay: account.paymentDueDay,
        cardBalancePrimary: account.cardBalancePrimary,
      );
}
