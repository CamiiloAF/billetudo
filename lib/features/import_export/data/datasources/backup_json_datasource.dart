import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/result.dart';
import '../../domain/entities/cancellation_token.dart';
import '../../domain/entities/progress_callback.dart';
import '../../domain/entities/restore_mode.dart';

/// This copy format's own version — bumped only when the JSON *shape* below
/// changes, independent of `AppDatabase.schemaVersion`. See
/// `BackupHeader.formatVersion`.
const int backupFormatVersion = 1;

/// Placeholder until a `PackageInfo`-backed source of the running app's own
/// version is wired into `core/` (out of this feature's domain+data scope) —
/// tracked so `RestoreBackup`'s summary always has *something* to show; not
/// used for any gating decision (only `formatVersion`/`schemaVersion` are).
const String _appVersionPlaceholder = '0.0.3';

/// Every sync-managed table this copy carries, in FK-safe order (children
/// before parents) — the order `RestoreBackup`'s "reemplazar todo" wipe and
/// `undoBatch`-style cleanups already use elsewhere in this feature.
const List<String> backupTableNames = [
  'transactionTags',
  'scheduledPaymentTags',
  'scheduledPaymentOccurrences',
  'debtEntries',
  'goalContributions',
  'goalQuickAmounts',
  'budgetAccounts',
  'budgetCategories',
  'budgetPeriodOverrides',
  'transactions',
  'scheduledPayments',
  'debts',
  'goals',
  'budgets',
  'tags',
  'categories',
  'accounts',
  'importBatches',
  'appSettings',
];

/// The reverse of [backupTableNames]: parents before children, with
/// `appSettings` kept last (it can reference `budgets` via
/// `featuredBudgetId`). Restoring/merging must insert in THIS order — a
/// child row referencing a parent that has not been inserted yet (ej.
/// `transactions.accountId` pointing at an `Accounts` row) is a real bug,
/// not a cosmetic one: `restore()` used to reuse [backupTableNames] for
/// both the delete pass (correctly children-first) AND the insert pass
/// (incorrectly children-first too), so restoring into an empty database —
/// exactly what "reemplazar todo" does right before restoring — inserted
/// children ahead of the parents they reference.
const List<String> restoreInsertOrder = [
  'importBatches',
  'accounts',
  'categories',
  'tags',
  'budgets',
  'goals',
  'debts',
  'scheduledPayments',
  'transactions',
  'budgetPeriodOverrides',
  'budgetCategories',
  'budgetAccounts',
  'goalQuickAmounts',
  'goalContributions',
  'debtEntries',
  'scheduledPaymentOccurrences',
  'scheduledPaymentTags',
  'transactionTags',
  'appSettings',
];

/// Reads/writes the `.billetudo.json` full copy (HU-03/HU-04), table by
/// table, straight off `AppDatabase` — a copy of raw storage state
/// (`deletedAt`/`tombstonedAt` included), which is why this reads Drift
/// directly instead of going through any other feature's repository (those
/// intentionally hide tombstoned/deleted rows).
@lazySingleton
class BackupJsonDatasource {
  const BackupJsonDatasource(this._db);

  final db.AppDatabase _db;

  FutureResult<Map<String, dynamic>> createFullBackup(
    String outputPath, {
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final file = File(outputPath);
    IOSink? sink;
    try {
      await file.parent.create(recursive: true);
      sink = file.openWrite();

      final rowCounts = <String, int>{};
      final totalTables = backupTableNames.length;
      onProgress?.call(0, totalTables);
      sink.write('{');
      sink.write('"formatVersion":$backupFormatVersion,');
      sink.write('"schemaVersion":${_db.schemaVersion},');
      sink.write('"appVersion":${jsonEncode(_appVersionPlaceholder)},');
      sink.write('"createdAt":${jsonEncode(DateTime.now().toIso8601String())},');
      sink.write('"tables":{');

      for (var i = 0; i < totalTables; i++) {
        if (cancellationToken?.isCancelled ?? false) {
          throw const OperationCancelledException();
        }
        final name = backupTableNames[i];
        final rows = await _readTableAsJson(name);
        rowCounts[name] = rows.length;
        sink.write('${jsonEncode(name)}:${jsonEncode(rows)}');
        if (i < totalTables - 1) {
          sink.write(',');
        }
        onProgress?.call(i + 1, totalTables);
      }
      sink.write('}}');
      await sink.flush();
      await sink.close();

      return Right({
        'formatVersion': backupFormatVersion,
        'schemaVersion': _db.schemaVersion,
        'appVersion': _appVersionPlaceholder,
        'createdAt': DateTime.now(),
        'rowCountsByTable': rowCounts,
      });
    } on OperationCancelledException {
      await sink?.close();
      if (file.existsSync()) {
        await file.delete();
      }
      return const Left(
        IoFailure('backup cancelled', reason: IoFailureReason.cancelled),
      );
    } on FileSystemException catch (e, st) {
      await sink?.close();
      return Left(
        IoFailure('could not write backup file', cause: e, stackTrace: st),
      );
    }
  }

  FutureResult<Map<String, dynamic>> parseHeader(String inputPath) async {
    final decodedResult = await _decode(inputPath);
    if (decodedResult case Left(value: final failure)) {
      return Left(failure);
    }
    final decoded = (decodedResult as Right<Failure, Map<String, dynamic>>).value;
    final tables = decoded['tables'] as Map<String, dynamic>? ?? const {};
    return Right({
      'formatVersion': decoded['formatVersion'] as int? ?? 0,
      'schemaVersion': decoded['schemaVersion'] as int? ?? 0,
      'appVersion': decoded['appVersion'] as String? ?? '',
      'createdAt': DateTime.tryParse(decoded['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      'rowCountsByTable': {
        for (final entry in tables.entries)
          entry.key: (entry.value as List<dynamic>).length,
      },
    });
  }

  FutureResult<Map<String, ({int created, int updated, int skipped})>> restore(
    String inputPath, {
    required RestoreMode mode,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final decodedResult = await _decode(inputPath);
    if (decodedResult case Left(value: final failure)) {
      return Left(failure);
    }
    final decoded = (decodedResult as Right<Failure, Map<String, dynamic>>).value;
    final tables = decoded['tables'] as Map<String, dynamic>? ?? const {};

    final result = <String, ({int created, int updated, int skipped})>{};
    final totalTables = backupTableNames.length;
    onProgress?.call(0, totalTables);
    try {
      await _db.transaction(() async {
        if (mode == RestoreMode.replaceAll) {
          for (final name in backupTableNames) {
            if (name == 'appSettings') {
              continue; // singleton row, always overwritten below instead.
            }
            await _db.customStatement('DELETE FROM ${_sqlNameOf(name)}');
          }
        }
        for (var i = 0; i < totalTables; i++) {
          if (cancellationToken?.isCancelled ?? false) {
            throw const OperationCancelledException();
          }
          // Parents before children (restoreInsertOrder) — the reverse of
          // the delete pass above, which is correctly children-first.
          final name = restoreInsertOrder[i];
          final rows = (tables[name] as List<dynamic>?) ?? const [];
          result[name] = await _mergeTable(name, rows);
          onProgress?.call(i + 1, totalTables);
        }
      });
      return Right(result);
    } on OperationCancelledException {
      // HU-04/HU-09: cancelling mid-restore throws inside the Drift
      // transaction, which rolls it back — no table is left half-merged.
      return const Left(
        IoFailure('restore cancelled', reason: IoFailureReason.cancelled),
      );
    } catch (e, st) {
      return Left(
        DatabaseFailure('could not restore backup', cause: e, stackTrace: st),
      );
    }
  }

  Future<({int created, int updated, int skipped})> _mergeTable(
    String name,
    List<dynamic> rows,
  ) async {
    var created = 0;
    var updated = 0;
    var skipped = 0;
    for (final raw in rows) {
      final json = raw as Map<String, dynamic>;
      final id = json['id'] as String;
      final incomingUpdatedAt = (json['updatedAt'] as num).toInt();

      final existing = await _db
          .customSelect(
            'SELECT updated_at FROM ${_sqlNameOf(name)} WHERE id = ?',
            variables: [Variable.withString(id)],
          )
          .getSingleOrNull();

      if (existing == null) {
        await _insertRow(name, json);
        created++;
      } else if (incomingUpdatedAt > existing.read<int>('updated_at')) {
        await _insertRow(name, json);
        updated++;
      } else {
        skipped++;
      }
    }
    return (created: created, updated: updated, skipped: skipped);
  }

  Future<void> _insertRow(String name, Map<String, dynamic> json) async {
    switch (name) {
      case 'accounts':
        await _db
            .into(_db.accounts)
            .insertOnConflictUpdate(db.Account.fromJson(json));
      case 'categories':
        await _db
            .into(_db.categories)
            .insertOnConflictUpdate(db.Category.fromJson(json));
      case 'transactions':
        await _db
            .into(_db.transactions)
            .insertOnConflictUpdate(db.Transaction.fromJson(json));
      case 'budgets':
        await _db.into(_db.budgets).insertOnConflictUpdate(db.Budget.fromJson(json));
      case 'goals':
        await _db.into(_db.goals).insertOnConflictUpdate(db.Goal.fromJson(json));
      case 'goalContributions':
        await _db
            .into(_db.goalContributions)
            .insertOnConflictUpdate(db.GoalContribution.fromJson(json));
      case 'goalQuickAmounts':
        await _db
            .into(_db.goalQuickAmounts)
            .insertOnConflictUpdate(db.GoalQuickAmount.fromJson(json));
      case 'debts':
        await _db.into(_db.debts).insertOnConflictUpdate(db.Debt.fromJson(json));
      case 'debtEntries':
        await _db
            .into(_db.debtEntries)
            .insertOnConflictUpdate(db.DebtEntry.fromJson(json));
      case 'scheduledPayments':
        await _db
            .into(_db.scheduledPayments)
            .insertOnConflictUpdate(db.ScheduledPayment.fromJson(json));
      case 'tags':
        await _db.into(_db.tags).insertOnConflictUpdate(db.Tag.fromJson(json));
      case 'transactionTags':
        await _db
            .into(_db.transactionTags)
            .insertOnConflictUpdate(db.TransactionTag.fromJson(json));
      case 'scheduledPaymentTags':
        await _db
            .into(_db.scheduledPaymentTags)
            .insertOnConflictUpdate(db.ScheduledPaymentTag.fromJson(json));
      case 'scheduledPaymentOccurrences':
        await _db
            .into(_db.scheduledPaymentOccurrences)
            .insertOnConflictUpdate(db.ScheduledPaymentOccurrence.fromJson(json));
      case 'budgetAccounts':
        await _db
            .into(_db.budgetAccounts)
            .insertOnConflictUpdate(db.BudgetAccount.fromJson(json));
      case 'budgetCategories':
        await _db
            .into(_db.budgetCategories)
            .insertOnConflictUpdate(db.BudgetCategory.fromJson(json));
      case 'budgetPeriodOverrides':
        await _db
            .into(_db.budgetPeriodOverrides)
            .insertOnConflictUpdate(db.BudgetPeriodOverrideRow.fromJson(json));
      case 'appSettings':
        await _db
            .into(_db.appSettings)
            .insertOnConflictUpdate(db.AppSetting.fromJson(json));
      case 'importBatches':
        await _db
            .into(_db.importBatches)
            .insertOnConflictUpdate(db.ImportBatche.fromJson(json));
      default:
        throw StateError('unknown backup table "$name"');
    }
  }

  /// HU-03: the unencrypted `.billetudo.json` copy never carries `userId` —
  /// it is a sync-only column (added `userId` per `_SyncColumns`, see
  /// `app_database.dart`), not user data, and this copy can be shared/backed
  /// up outside the app's control. Every table mixes in `_SyncColumns`, so
  /// this strips it uniformly instead of repeating the exclusion per table.
  Future<List<Map<String, dynamic>>> _readTableAsJson(String name) async {
    final rows = await _readTableRowsAsJson(name);
    for (final row in rows) {
      row.remove('userId');
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> _readTableRowsAsJson(String name) async {
    switch (name) {
      case 'accounts':
        return [for (final r in await _db.select(_db.accounts).get()) r.toJson()];
      case 'categories':
        return [for (final r in await _db.select(_db.categories).get()) r.toJson()];
      case 'transactions':
        return [for (final r in await _db.select(_db.transactions).get()) r.toJson()];
      case 'budgets':
        return [for (final r in await _db.select(_db.budgets).get()) r.toJson()];
      case 'goals':
        return [for (final r in await _db.select(_db.goals).get()) r.toJson()];
      case 'goalContributions':
        return [
          for (final r in await _db.select(_db.goalContributions).get()) r.toJson(),
        ];
      case 'goalQuickAmounts':
        return [
          for (final r in await _db.select(_db.goalQuickAmounts).get()) r.toJson(),
        ];
      case 'debts':
        return [for (final r in await _db.select(_db.debts).get()) r.toJson()];
      case 'debtEntries':
        return [for (final r in await _db.select(_db.debtEntries).get()) r.toJson()];
      case 'scheduledPayments':
        return [
          for (final r in await _db.select(_db.scheduledPayments).get()) r.toJson(),
        ];
      case 'tags':
        return [for (final r in await _db.select(_db.tags).get()) r.toJson()];
      case 'transactionTags':
        return [
          for (final r in await _db.select(_db.transactionTags).get()) r.toJson(),
        ];
      case 'scheduledPaymentTags':
        return [
          for (final r in await _db.select(_db.scheduledPaymentTags).get())
            r.toJson(),
        ];
      case 'scheduledPaymentOccurrences':
        return [
          for (final r in await _db.select(_db.scheduledPaymentOccurrences).get())
            r.toJson(),
        ];
      case 'budgetAccounts':
        return [
          for (final r in await _db.select(_db.budgetAccounts).get()) r.toJson(),
        ];
      case 'budgetCategories':
        return [
          for (final r in await _db.select(_db.budgetCategories).get()) r.toJson(),
        ];
      case 'budgetPeriodOverrides':
        return [
          for (final r in await _db.select(_db.budgetPeriodOverrides).get())
            r.toJson(),
        ];
      case 'appSettings':
        return [for (final r in await _db.select(_db.appSettings).get()) r.toJson()];
      case 'importBatches':
        return [for (final r in await _db.select(_db.importBatches).get()) r.toJson()];
      default:
        throw StateError('unknown backup table "$name"');
    }
  }

  /// snake_case SQL table name from the camelCase key used in the JSON/Dart
  /// side — Drift's own naming convention for every table here.
  String _sqlNameOf(String camelCase) => camelCase.replaceAllMapped(
        RegExp('[A-Z]'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      );

  FutureResult<Map<String, dynamic>> _decode(String inputPath) async {
    try {
      final file = File(inputPath);
      if (!file.existsSync()) {
        return const Left(
          IoFailure(
            'backup file does not exist',
            reason: IoFailureReason.unreadableFile,
          ),
        );
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return const Left(
          IoFailure('backup file is empty', reason: IoFailureReason.emptyFile),
        );
      }
      return Right(jsonDecode(content) as Map<String, dynamic>);
    } on FormatException catch (e, st) {
      return Left(
        IoFailure(
          'backup file is not valid JSON',
          reason: IoFailureReason.unreadableFile,
          cause: e,
          stackTrace: st,
        ),
      );
    } on FileSystemException catch (e, st) {
      return Left(
        IoFailure('could not read backup file', cause: e, stackTrace: st),
      );
    }
  }
}
