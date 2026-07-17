import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_balance.dart';
import '../../domain/entities/account_deletion_impact.dart';
import '../../domain/entities/account_draft.dart';
import '../../domain/entities/account_number_edit.dart';
import '../../domain/entities/account_with_balance.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_number_local_datasource.dart';
import '../datasources/accounts_local_datasource.dart';
import '../models/account_mapper.dart';

/// Drift + secure storage implementation of [AccountRepository].
///
/// Owns two cross-cutting rules: `updatedAt` is stamped on **every** write (via
/// the mapper's companions), and the full account number only ever travels to
/// [AccountNumberLocalDatasource] — `accountNumberEnc` is never written, so it
/// stays NULL forever (HU-03).
@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._local, this._numbers);

  final AccountsLocalDatasource _local;
  final AccountNumberLocalDatasource _numbers;

  @override
  Stream<Result<List<AccountWithBalance>>> watchActiveAccounts() =>
      _watchList(archived: false);

  @override
  Stream<Result<List<AccountWithBalance>>> watchArchivedAccounts() =>
      _watchList(archived: true);

  @override
  Stream<Result<AccountWithBalance>> watchAccount(String id) => _guardStream(
        _local.watchAccount(id).map(
          (rows) {
            if (rows.isEmpty) {
              return Left(NotFoundFailure('account "$id" does not exist'));
            }
            return Right(_toAccountWithBalance(rows.first));
          },
        ),
      );

  @override
  FutureResult<Account> getAccount(String id) => _guard(() async {
        final row = await _local.getAccount(id);
        if (row == null) {
          return Left(NotFoundFailure('account "$id" does not exist'));
        }
        return Right(AccountMapper.toEntity(row));
      });

  @override
  FutureResult<Account> createAccount(AccountDraft draft) => _guard(() async {
        final now = DateTime.now();
        final row = await _local.insertAccount(
          AccountMapper.toInsertCompanion(
            draft,
            sortOrder: await _local.nextSortOrder(),
            now: now,
          ),
        );

        // Only once the row exists do we know its id, which keys the secure
        // entry. A brand new id owns no entry yet, so only an actual number is
        // worth writing: clearing would be a no-op that can still fail on a
        // locked Keystore and sink a creation that never needed it.
        if (draft.numberEdit case SetAccountNumber(:final value)) {
          final stored = await _numbers.write(row.id, value);
          if (stored case Left(value: final failure)) {
            // The account the user asked for includes its number, so this is
            // not a half success to hand back. The row has to go with it: the
            // form has no id yet, so a second Save would create a *second*
            // account instead of updating this one.
            await _local.hardDeleteAccount(row.id);
            return Left(failure);
          }
        }
        return Right(AccountMapper.toEntity(row));
      });

  @override
  FutureResult<Account> updateAccount(AccountDraft draft) => _guard(() async {
        final id = draft.id;
        if (id == null) {
          return const Left(
            ValidationFailure(
              'cannot update an account without an id',
              field: AccountDraft.fieldId,
            ),
          );
        }

        final row = await _local.updateAccount(
          id,
          AccountMapper.toUpdateCompanion(draft, now: DateTime.now()),
        );
        if (row == null) {
          return Left(NotFoundFailure('account "$id" does not exist'));
        }

        // A type that no longer admits a number (cash, card) must not leave one
        // behind in secure storage.
        final numberEdit = draft.type.allowsFullAccountNumber
            ? draft.numberEdit
            : const ClearAccountNumber();
        final stored = await _applyNumber(id, numberEdit);
        if (stored case Left(value: final failure)) {
          return Left(failure);
        }
        return Right(AccountMapper.toEntity(row));
      });

  /// The number is the one piece of an account that lives **only** on this
  /// device (HU-03): nothing in Drift or the cloud can restore it. So a draft
  /// that does not know it reaches secure storage as "do nothing", never as a
  /// delete.
  FutureResult<Unit> _applyNumber(String id, AccountNumberEdit edit) =>
      switch (edit) {
        SetAccountNumber(:final value) => _numbers.write(id, value),
        ClearAccountNumber() => _numbers.delete(id),
        KeepAccountNumber() => Future<Result<Unit>>.value(const Right(unit)),
      };

  @override
  FutureResult<Unit> setArchived(String id, {required bool archived}) =>
      _guard(() async {
        final row = await _local.updateAccount(
          id,
          AccountMapper.archivedCompanion(
            archived: archived,
            now: DateTime.now(),
          ),
        );
        if (row == null) {
          return Left(NotFoundFailure('account "$id" does not exist'));
        }
        return const Right(unit);
      });

  /// HU-08. Stamps `tombstonedAt`: a *referential-integrity tombstone*, not the
  /// UX trash. The row has to survive so `Transactions.accountId` keeps pointing
  /// at something real, which is precisely what that column means — `deletedAt`
  /// stays reserved for the reversible trash/undo the project documents.
  ///
  /// Consequences, on purpose and irreversible: the account disappears from
  /// every query (they all filter `tombstonedAt IS NULL`) and there is no
  /// restore path, unlike the archive flow. Wiping the number from secure
  /// storage is what makes it unrecoverable, and it is what HU-08 asks for.
  ///
  /// UNRESOLVED, decide before wiring sync: PowerSync propagates real DELETEs
  /// on its own, so this row will live in Supabase forever. Either these
  /// tombstones get a real DELETE once no transaction references them, or the
  /// sync rules have to filter them out explicitly.
  @override
  FutureResult<Unit> softDeleteAccount(String id) => _guard(() async {
        final row = await _local.updateAccount(
          id,
          AccountMapper.tombstonedCompanion(now: DateTime.now()),
        );
        if (row == null) {
          return Left(NotFoundFailure('account "$id" does not exist'));
        }
        // The row survives (transactions still point at it), but the number
        // must not outlive the account the user deleted.
        return _numbers.delete(id);
      });

  @override
  FutureResult<Unit> reorderAccounts(List<String> orderedIds) =>
      _guard(() async {
        await _local.reorderAccounts(orderedIds, DateTime.now());
        return const Right(unit);
      });

  @override
  FutureResult<String?> readAccountNumber(String id) => _numbers.read(id);

  @override
  FutureResult<AccountDeletionImpact> getDeletionImpact(String id) =>
      _guard(() async {
        final row = await _local.getAccount(id);
        if (row == null) {
          return Left(NotFoundFailure('account "$id" does not exist'));
        }
        final otherActive = await _local.countOtherActiveAccounts(id);
        return Right(
          AccountDeletionImpact(
            transactionCount: await _local.countTransactions(id),
            goalCount: await _local.countLinkedGoals(id),
            debtCount: await _local.countLinkedDebts(id),
            budgetCount: await _local.countReferencingBudgets(id),
            // Only an active account can be "the last one": deleting an
            // archived account never leaves the app with nowhere to record.
            isLastAccount: !row.archived && otherActive == 0,
          ),
        );
      });

  @override
  FutureResult<bool> hasTransactions(String id) => _guard(() async {
        final count = await _local.countTransactions(id);
        return Right(count > 0);
      });

  @override
  FutureResult<Unit> setCardBalancePrimary(String id, CardBalanceView view) =>
      _guard(() async {
        final row = await _local.updateAccount(
          id,
          AccountMapper.cardBalancePrimaryCompanion(
            view: view,
            now: DateTime.now(),
          ),
        );
        if (row == null) {
          return Left(NotFoundFailure('account "$id" does not exist'));
        }
        return const Right(unit);
      });

  Stream<Result<List<AccountWithBalance>>> _watchList({
    required bool archived,
  }) =>
      _guardStream(
        _local.watchAccounts(archived: archived).map(
              (rows) => Right(rows.map(_toAccountWithBalance).toList()),
            ),
      );

  AccountWithBalance _toAccountWithBalance(AccountWithMovementRows row) {
    final account = AccountMapper.toEntity(row.account);
    return AccountWithBalance(
      account: account,
      // The balance rule lives in the domain; here we only feed it rows.
      balance: AccountBalance.fromMovements(
        account: account,
        movements: row.movements
            .map((movement) => AccountMapper.toMovement(movement, account.id)),
      ),
    );
  }

  /// Turns any infrastructure exception into a `Failure`, so nothing escapes
  /// the data layer as a raw exception.
  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      return Left(
        DatabaseFailure('accounts query failed', cause: e, stackTrace: st),
      );
    }
  }

  /// Same for streams: a query error becomes a `Left` **emission** instead of a
  /// stream error, so the cubit can render the error state without the
  /// subscription dying.
  Stream<Result<T>> _guardStream<T>(Stream<Result<T>> source) =>
      source.transform(
        StreamTransformer<Result<T>, Result<T>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) => sink.add(
            Left(
              DatabaseFailure(
                'accounts stream failed',
                cause: error,
                stackTrace: stackTrace,
              ),
            ),
          ),
        ),
      );
}
