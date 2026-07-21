import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/result.dart';
import '../../../transactions/data/models/transaction_mapper.dart';
import '../../../transactions/domain/entities/transaction.dart' as tx;
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../../domain/entities/scheduled_payment.dart';
import '../../domain/entities/scheduled_payment_detail.dart';
import '../../domain/entities/scheduled_payment_draft.dart';
import '../../domain/entities/scheduled_payment_occurrence.dart';
import '../../domain/entities/scheduled_payment_summary.dart';
import '../../domain/entities/snooze_outcome.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/scheduled_payment_repository.dart';
import '../../domain/usecases/project_upcoming_occurrences.dart';
import '../datasources/scheduled_payment_tags_local_datasource.dart';
import '../datasources/scheduled_payments_local_datasource.dart'
    show ScheduledPaymentRowWithJoins, ScheduledPaymentsLocalDatasource;
import '../models/scheduled_payment_mapper.dart';
import '../models/scheduled_payment_occurrence_mapper.dart';

/// Drift implementation of [ScheduledPaymentRepository].
///
/// Owns the cross-cutting rules of this feature: `updatedAt` stamped on
/// every write, deletion via `tombstonedAt` (never `deletedAt`, HU-05), the
/// idempotent catch-up algorithm (HU-02), and the "confirmation sheet is the
/// only path" invariant of HU-03 (both `confirmOccurrence` and the
/// automatic branch of `generateDueScheduledPayments` funnel through the
/// same [_generateTransaction] helper).
@LazySingleton(as: ScheduledPaymentRepository)
class ScheduledPaymentRepositoryImpl implements ScheduledPaymentRepository {
  const ScheduledPaymentRepositoryImpl(this._local, this._tags, this._crash);

  final ScheduledPaymentsLocalDatasource _local;
  final ScheduledPaymentTagsLocalDatasource _tags;
  final CrashReporter _crash;

  static const List<db.ScheduledOccurrenceStatus> _awaitingStatuses = [
    db.ScheduledOccurrenceStatus.pending,
    db.ScheduledOccurrenceStatus.snoozed,
  ];

  // -- Templates ----------------------------------------------------------

  @override
  Stream<Result<List<ScheduledPaymentSummary>>>
      watchActiveScheduledPayments() => _guardStream(
            _local.watchActiveScheduledPayments().map(
                  (rows) => Right(rows.map(_toSummary).toList()),
                ),
          );

  @override
  Stream<Result<List<ScheduledPaymentSummary>>>
      watchFinishedScheduledPayments() => _guardStream(
            _local.watchFinishedScheduledPayments().map(
                  (rows) => Right(rows.map(_toSummary).toList()),
                ),
          );

  @override
  Stream<Result<ScheduledPaymentDetail>> watchScheduledPaymentDetail(
    String id, {
    int historyPageSize = 3,
  }) =>
      _guardStream(
        _local.watchScheduledPaymentRow(id).asyncMap((row) async {
          if (row == null) {
            return Left(
                NotFoundFailure('scheduled payment "$id" does not exist'));
          }
          final tags = await _tags.tagsFor(id);
          final pendingRow = await _ensureDuePendingOccurrence(
            row.scheduledPayment,
            DateTime.now(),
          );
          // The nearest awaiting occurrence — due OR snoozed into the future —
          // so the hero shows a snoozed payment's postponed date instead of the
          // template's cursor.
          final nextAwaiting =
              await _local.getNextAwaitingOccurrence(id);
          final history = await _local.getHistory(
            id,
            offset: 0,
            limit: historyPageSize,
          );
          final historyTotalCount = await _local.countHistory(id);

          return Right(
            ScheduledPaymentDetail(
              scheduledPayment: ScheduledPaymentMapper.toEntity(
                row.scheduledPayment,
              ),
              accountName: row.account.name,
              categoryName: row.category?.name,
              categoryIcon: row.category?.icon,
              categoryColor: row.category?.color,
              transferAccountName: row.transferAccount?.name,
              tags: tags.map(_toTagEntity).toList(),
              pendingOccurrence: pendingRow == null
                  ? null
                  : PendingScheduledOccurrence(
                      occurrence: ScheduledPaymentOccurrenceMapper.toEntity(
                        pendingRow,
                      ),
                      scheduledPayment: ScheduledPaymentMapper.toEntity(
                        row.scheduledPayment,
                      ),
                      accountName: row.account.name,
                      categoryName: row.category?.name,
                      categoryIcon: row.category?.icon,
                      categoryColor: row.category?.color,
                      transferAccountName: row.transferAccount?.name,
                      tagIds: tags.map((t) => t.id).toList(),
                    ),
              nextAwaitingDate: nextAwaiting == null
                  ? null
                  : (nextAwaiting.snoozedToDate ?? nextAwaiting.occurrenceDate),
              history: history.map(TransactionMapper.toEntity).toList(),
              historyTotalCount: historyTotalCount,
            ),
          );
        }),
      );

  @override
  FutureResult<List<tx.Transaction>> getScheduledPaymentHistory(
    String scheduledPaymentId, {
    required int offset,
    required int limit,
  }) =>
      _guard(() async {
        final rows = await _local.getHistory(
          scheduledPaymentId,
          offset: offset,
          limit: limit,
        );
        return Right(rows.map(TransactionMapper.toEntity).toList());
      });

  @override
  FutureResult<ScheduledPayment> getScheduledPayment(String id) =>
      _guard(() async {
        final row = await _local.getScheduledPayment(id);
        if (row == null) {
          return Left(
              NotFoundFailure('scheduled payment "$id" does not exist'));
        }
        return Right(ScheduledPaymentMapper.toEntity(row));
      });

  @override
  FutureResult<ScheduledPayment> createScheduledPayment(
    ScheduledPaymentDraft draft,
  ) =>
      _guard(() async {
        final now = DateTime.now();
        final row = await _local.insertScheduledPayment(
          ScheduledPaymentMapper.toInsertCompanion(draft, now: now),
        );
        if (draft.type != ScheduledPaymentType.transfer) {
          await _tags.replaceTags(row.id, draft.tagIds, now);
        }
        return Right(ScheduledPaymentMapper.toEntity(row));
      });

  @override
  FutureResult<ScheduledPayment> updateScheduledPayment(
    ScheduledPaymentDraft draft,
  ) =>
      _guard(() async {
        final id = draft.id;
        if (id == null) {
          return const Left(
            ValidationFailure(
              'cannot update a scheduled payment without an id',
              field: ScheduledPaymentDraft.fieldId,
            ),
          );
        }
        final now = DateTime.now();
        final row = await _local.updateScheduledPayment(
          id,
          ScheduledPaymentMapper.toUpdateCompanion(draft, now: now),
        );
        if (row == null) {
          return Left(
              NotFoundFailure('scheduled payment "$id" does not exist'));
        }
        await _tags.replaceTags(id, draft.tagIds, now);
        return Right(ScheduledPaymentMapper.toEntity(row));
      });

  @override
  FutureResult<Unit> deleteScheduledPayment(String id) => _guard(() async {
        final row = await _local.tombstoneScheduledPayment(
          id,
          ScheduledPaymentMapper.tombstonedCompanion(now: DateTime.now()),
        );
        if (row == null) {
          return Left(
              NotFoundFailure('scheduled payment "$id" does not exist'));
        }
        return const Right(unit);
      });

  @override
  FutureResult<Unit> setScheduledPaymentTags(
    String scheduledPaymentId,
    List<String> tagIds,
  ) =>
      _guard(() async {
        final template = await _local.getScheduledPayment(scheduledPaymentId);
        if (template == null) {
          return Left(
            NotFoundFailure(
              'scheduled payment "$scheduledPaymentId" does not exist',
            ),
          );
        }
        await _tags.replaceTags(scheduledPaymentId, tagIds, DateTime.now());
        return const Right(unit);
      });

  // -- Tags -----------------------------------------------------------------

  @override
  Stream<Result<List<Tag>>> watchTags() => _guardStream(
        _tags.watchTags().map(
              (rows) => Right(rows.map(_toTagEntity).toList()),
            ),
      );

  @override
  FutureResult<Tag?> findTagByName(String name) => _guard(() async {
        final row = await _tags.getTagByName(name);
        return Right(row == null ? null : _toTagEntity(row));
      });

  @override
  FutureResult<Tag> createTag(String name) => _guard(() async {
        final now = DateTime.now();
        final row = await _tags.insertTag(
          db.TagsCompanion.insert(
            name: name,
            createdAt: Value(now),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
        return Right(_toTagEntity(row));
      });

  // -- Pending occurrences (HU-03) -------------------------------------------

  @override
  Stream<Result<List<PendingScheduledOccurrence>>> watchPendingOccurrences() =>
      _guardStream(
        _local.watchPendingOccurrences().asyncMap((rows) async {
          final items = await Future.wait(
            rows.map((row) async {
              final tagIds = await _tags.tagIdsFor(
                row.scheduledPayment.id,
              );
              return PendingScheduledOccurrence(
                occurrence:
                    ScheduledPaymentOccurrenceMapper.toEntity(row.occurrence),
                scheduledPayment:
                    ScheduledPaymentMapper.toEntity(row.scheduledPayment),
                accountName: row.account.name,
                categoryName: row.category?.name,
                categoryIcon: row.category?.icon,
                categoryColor: row.category?.color,
                transferAccountName: row.transferAccount?.name,
                tagIds: tagIds,
              );
            }),
          );
          return Right(items);
        }),
      );

  // -- Catch-up generation (HU-02) -------------------------------------------

  @override
  FutureResult<Unit> generateDueScheduledPayments({required DateTime now}) =>
      _guard(() async {
        final templates = await _local.getActiveTemplatesForCatchup();
        for (final template in templates) {
          await _catchUpTemplate(template, now);
        }
        return const Right(unit);
      });

  Future<void> _catchUpTemplate(
      db.ScheduledPayment template, DateTime now) async {
    var cursor = template.nextDate;
    DateTime? lastProcessed;

    while (!cursor.isAfter(now)) {
      final endDate = template.endDate;
      if (endDate != null && cursor.isAfter(endDate)) {
        break;
      }

      final existing = await _local.getOccurrenceForDate(template.id, cursor);
      if (existing == null) {
        if (template.requiresConfirmation) {
          await _insertPendingOccurrence(
            scheduledPaymentId: template.id,
            occurrenceDate: cursor,
            now: now,
          );
        } else {
          final generated = await _generateTransaction(
            template,
            date: cursor,
            accountId: template.accountId,
            amountMinor: template.amountMinor,
            now: now,
          );
          await _local.insertOccurrence(
            ScheduledPaymentOccurrenceMapper.confirmedInsertCompanion(
              scheduledPaymentId: template.id,
              occurrenceDate: cursor,
              generatedTransactionId: generated.id,
              now: now,
            ),
          );
        }
      }

      lastProcessed = cursor;
      if (template.frequency == db.ScheduleFrequency.once) {
        break;
      }
      cursor = ProjectUpcomingOccurrences.advance(
        cursor,
        ScheduledPaymentMapper.frequencyToDomain(template.frequency),
        template.interval,
      );
    }

    if (lastProcessed == null) {
      return;
    }
    // `once` never advances (criterion 4): re-writing the same `nextDate` is
    // a harmless no-op that keeps this branch simple.
    final newNextDate = template.frequency == db.ScheduleFrequency.once
        ? template.nextDate
        : cursor;
    await _local.updateScheduledPayment(
      template.id,
      ScheduledPaymentMapper.nextDateCompanion(nextDate: newNextDate, now: now),
    );
  }

  // -- Confirm / skip / snooze (HU-03/HU-07) ---------------------------------

  @override
  FutureResult<tx.Transaction> confirmOccurrence({
    required String occurrenceId,
    required DateTime date,
    required String accountId,
    required int amountMinor,
  }) =>
      _guard(() async {
        final occurrence = await _local.getOccurrence(occurrenceId);
        if (occurrence == null) {
          return Left(
            NotFoundFailure('occurrence "$occurrenceId" does not exist'),
          );
        }
        if (!_awaitingStatuses.contains(occurrence.status)) {
          return const Left(
            ValidationFailure('this occurrence was already resolved'),
          );
        }
        final template =
            await _local.getScheduledPayment(occurrence.scheduledPaymentId);
        if (template == null) {
          return Left(
            NotFoundFailure(
              'scheduled payment "${occurrence.scheduledPaymentId}" does not exist',
            ),
          );
        }

        final now = DateTime.now();
        final generated = await _generateTransaction(
          template,
          date: date,
          accountId: accountId,
          amountMinor: amountMinor,
          now: now,
        );
        await _local.updateOccurrence(
          occurrenceId,
          ScheduledPaymentOccurrenceMapper.confirmCompanion(
            generatedTransactionId: generated.id,
            now: now,
          ),
        );
        await _advanceCursorPast(template, occurrence.occurrenceDate, now);
        return Right(TransactionMapper.toEntity(generated));
      });

  @override
  FutureResult<Unit> skipOccurrence(String occurrenceId) => _guard(() async {
        final occurrence = await _local.getOccurrence(occurrenceId);
        if (occurrence == null) {
          return Left(
            NotFoundFailure('occurrence "$occurrenceId" does not exist'),
          );
        }
        if (!_awaitingStatuses.contains(occurrence.status)) {
          return const Left(
            ValidationFailure('this occurrence was already resolved'),
          );
        }
        final now = DateTime.now();
        await _local.updateOccurrence(
          occurrenceId,
          ScheduledPaymentOccurrenceMapper.skipCompanion(now: now),
        );
        // Skipping a "Confirmar ahora" occurrence still resolves that date, so
        // move the cursor forward just like a confirm would. No-op for a
        // catch-up occurrence (its date sits before the cursor already).
        final template =
            await _local.getScheduledPayment(occurrence.scheduledPaymentId);
        if (template != null) {
          await _advanceCursorPast(template, occurrence.occurrenceDate, now);
        }
        return const Right(unit);
      });

  @override
  FutureResult<Unit> undoSkipOccurrence(String occurrenceId) =>
      _guard(() async {
        final occurrence = await _local.getOccurrence(occurrenceId);
        if (occurrence == null) {
          return Left(
            NotFoundFailure('occurrence "$occurrenceId" does not exist'),
          );
        }
        if (occurrence.status != db.ScheduledOccurrenceStatus.skipped) {
          return const Left(
            ValidationFailure('this occurrence was not skipped'),
          );
        }
        await _local.updateOccurrence(
          occurrenceId,
          ScheduledPaymentOccurrenceMapper.undoSkipCompanion(
            now: DateTime.now(),
          ),
        );
        return const Right(unit);
      });

  @override
  FutureResult<SnoozeOutcome> snoozeOccurrence({
    required String scheduledPaymentId,
    required DateTime occurrenceDate,
    required DateTime newDate,
  }) =>
      _guard(() async {
        final now = DateTime.now();
        final existing = await _local.getOccurrenceForDate(
          scheduledPaymentId,
          occurrenceDate,
        );
        if (existing == null) {
          final created = await _local.insertOccurrence(
            ScheduledPaymentOccurrenceMapper.snoozeInsertCompanion(
              scheduledPaymentId: scheduledPaymentId,
              occurrenceDate: occurrenceDate,
              newDate: newDate,
              now: now,
            ),
          );
          return Right(
            SnoozeOutcome(
              occurrence: ScheduledPaymentOccurrenceMapper.toEntity(created),
              wasCreated: true,
            ),
          );
        }
        if (!_awaitingStatuses.contains(existing.status)) {
          return const Left(
            ValidationFailure('this occurrence was already resolved'),
          );
        }
        // Captured before the write: the snoozed date the row held immediately
        // before this snooze (null when it was still `pending`), so undo can
        // step back exactly one date instead of jumping to the original due
        // date.
        final previousSnoozedToDate = existing.snoozedToDate;
        final updated = await _local.updateOccurrence(
          existing.id,
          ScheduledPaymentOccurrenceMapper.snoozeCompanion(
            newDate: newDate,
            now: now,
          ),
        );
        return Right(
          SnoozeOutcome(
            occurrence: ScheduledPaymentOccurrenceMapper.toEntity(updated!),
            wasCreated: false,
            previousSnoozedToDate: previousSnoozedToDate,
          ),
        );
      });

  @override
  FutureResult<Unit> undoSnoozeOccurrence(
    String occurrenceId, {
    required bool wasCreated,
    DateTime? previousSnoozedToDate,
  }) =>
      _guard(() async {
        final occurrence = await _local.getOccurrence(occurrenceId);
        if (occurrence == null) {
          return Left(
            NotFoundFailure('occurrence "$occurrenceId" does not exist'),
          );
        }
        if (occurrence.status != db.ScheduledOccurrenceStatus.snoozed) {
          return const Left(
            ValidationFailure('this occurrence was not snoozed'),
          );
        }

        final now = DateTime.now();
        if (wasCreated) {
          // The snooze itself materialized this row (a not-yet-due next
          // occurrence, detail screen, criterion 10): undo removes it entirely
          // instead of leaving a premature occurrence behind.
          await _local.deleteOccurrence(occurrenceId);
        } else if (previousSnoozedToDate != null) {
          // A re-snooze: step back to the immediately previous snoozed date,
          // reusing the snooze write so status stays `snoozed`.
          await _local.updateOccurrence(
            occurrenceId,
            ScheduledPaymentOccurrenceMapper.snoozeCompanion(
              newDate: previousSnoozedToDate,
              now: now,
            ),
          );
        } else {
          // First snooze of a due `pending` occurrence: clear the snooze,
          // back to `pending`.
          await _local.updateOccurrence(
            occurrenceId,
            ScheduledPaymentOccurrenceMapper.undoSnoozeCompanion(now: now),
          );
        }
        return const Right(unit);
      });

  @override
  FutureResult<PendingScheduledOccurrence> advanceScheduledOccurrence(
    String scheduledPaymentId,
  ) =>
      _guard(() async {
        final row =
            await _local.watchScheduledPaymentRow(scheduledPaymentId).first;
        if (row == null) {
          return Left(
            NotFoundFailure(
              'scheduled payment "$scheduledPaymentId" does not exist',
            ),
          );
        }
        final template = row.scheduledPayment;
        // Any mode can be confirmed ahead of its date: `_ensureDuePendingOccurrence`
        // with `force: true` materializes (or reuses) the same `pending` row the
        // due-date path would, so the confirm/skip/snooze sheet works identically
        // for automatic and manual templates alike.
        //
        // The cursor is NOT advanced here: materializing a speculative
        // occurrence must not, by itself, move `nextDate` — otherwise merely
        // opening (and dismissing) the sheet would shift the next payment date
        // and leave a phantom pending. The advance happens only when the user
        // actually confirms/skips (see `confirmOccurrence`/`skipOccurrence`),
        // and a dismissed-without-action speculative occurrence is cleaned up
        // by `discardUnconfirmedAdvanceOccurrence`.
        final pendingRow = await _ensureDuePendingOccurrence(
          template,
          DateTime.now(),
          force: true,
        );
        if (pendingRow == null) {
          return const Left(
            ValidationFailure(
              'this scheduled payment has nothing left to confirm',
            ),
          );
        }
        final tags = await _tags.tagsFor(scheduledPaymentId);
        return Right(
          PendingScheduledOccurrence(
            occurrence: ScheduledPaymentOccurrenceMapper.toEntity(pendingRow),
            scheduledPayment: ScheduledPaymentMapper.toEntity(template),
            accountName: row.account.name,
            categoryName: row.category?.name,
            categoryIcon: row.category?.icon,
            categoryColor: row.category?.color,
            transferAccountName: row.transferAccount?.name,
            tagIds: tags.map((tag) => tag.id).toList(),
          ),
        );
      });

  @override
  FutureResult<Unit> discardUnconfirmedAdvanceOccurrence(String occurrenceId) =>
      _guard(() async {
        final occurrence = await _local.getOccurrence(occurrenceId);
        // Already gone, or the user acted (confirmed/skipped/snoozed): nothing
        // to clean up. Only a still-`pending` row is a candidate.
        if (occurrence == null ||
            occurrence.status != db.ScheduledOccurrenceStatus.pending) {
          return const Right(unit);
        }
        final template =
            await _local.getScheduledPayment(occurrence.scheduledPaymentId);
        // Only delete a speculative "Confirmar ahora" occurrence — one sitting
        // at or after the cursor. A genuine catch-up occurrence sits strictly
        // before the cursor and must survive a dismissed sheet.
        if (template != null &&
            _dateOnly(occurrence.occurrenceDate)
                .isBefore(_dateOnly(template.nextDate))) {
          return const Right(unit);
        }
        await _local.deleteOccurrence(occurrenceId);
        return const Right(unit);
      });

  // -- Shared helpers ---------------------------------------------------------

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Advances the template cursor (`nextDate`) one cadence past [occurrenceDate],
  /// mirroring `_catchUpTemplate`, but only when that date is at or after the
  /// current cursor. A catch-up occurrence sits strictly before `nextDate`
  /// (catch-up already advanced past it), so this is a no-op for it and never
  /// double-advances; a "Confirmar ahora" occurrence sits exactly at `nextDate`,
  /// so confirming/skipping it moves the cursor forward. `once` never advances
  /// (criterion 4).
  Future<void> _advanceCursorPast(
    db.ScheduledPayment template,
    DateTime occurrenceDate,
    DateTime now,
  ) async {
    if (template.frequency == db.ScheduleFrequency.once) {
      return;
    }
    if (_dateOnly(occurrenceDate).isBefore(_dateOnly(template.nextDate))) {
      return;
    }
    final advanced = ProjectUpcomingOccurrences.advance(
      template.nextDate,
      ScheduledPaymentMapper.frequencyToDomain(template.frequency),
      template.interval,
    );
    await _local.updateScheduledPayment(
      template.id,
      ScheduledPaymentMapper.nextDateCompanion(nextDate: advanced, now: now),
    );
  }

  /// Resolves the occurrence the detail screen shows/acts on as "pendiente"
  /// (HU-03). A manual-mode template usually already has one from the
  /// catch-up ledger (HU-02's `pending` branch); an automatic-mode template
  /// normally never does, because catch-up resolves its due dates straight
  /// into a `confirmed` transaction (`_catchUpTemplate`'s `else` branch).
  ///
  /// This closes that gap on demand: whenever the template's cursor
  /// (`nextDate`) is due (today or earlier per
  /// [ScheduledPaymentOccurrence.dateIsDueOn]) and nothing has been recorded
  /// for it yet, it materializes the same `pending` ledger row the manual
  /// branch of catch-up would have created — automatic or manual, so the
  /// existing confirm/skip/snooze flow (`ConfirmScheduledOccurrence` and
  /// friends) works identically for both modes from the detail screen.
  /// Idempotent: a later call, or the next catch-up run, finds the row
  /// already there and leaves it alone.
  ///
  /// [force] lifts the due-date gate — used only by
  /// [advanceScheduledOccurrence] ("Confirmar ahora", HU-05/`docs/bugfixes.md`
  /// point 1), whose whole point is materializing the occurrence *before*
  /// `nextDate` is due. It never lifts the other guards (tombstoned,
  /// past `endDate`, already-resolved date): those describe "nothing left to
  /// confirm", which forcing cannot change.
  Future<db.ScheduledPaymentOccurrence?> _ensureDuePendingOccurrence(
    db.ScheduledPayment template,
    DateTime now, {
    bool force = false,
  }) async {
    final existing = await _local.getNextAwaitingOccurrence(template.id);
    if (existing != null) {
      if (force) {
        return existing;
      }
      final effectiveDate = existing.snoozedToDate ?? existing.occurrenceDate;
      return ScheduledPaymentOccurrence.dateIsDueOn(effectiveDate, now)
          ? existing
          : null;
    }
    if (template.tombstonedAt != null) {
      return null;
    }
    final endDate = template.endDate;
    if (endDate != null && template.nextDate.isAfter(endDate)) {
      return null;
    }
    if (!force &&
        !ScheduledPaymentOccurrence.dateIsDueOn(template.nextDate, now)) {
      return null;
    }
    // Guards against a duplicate for an exact date already resolved (e.g. a
    // `once` template already `confirmed`, whose `nextDate` never advances
    // and would otherwise look "due" forever). Also applies under `force`:
    // an already-resolved date means there is nothing left to confirm, not
    // something to re-materialize.
    final alreadyRecorded = await _local.getOccurrenceForDate(
      template.id,
      template.nextDate,
    );
    if (alreadyRecorded != null) {
      return null;
    }
    return _insertPendingOccurrence(
      scheduledPaymentId: template.id,
      occurrenceDate: template.nextDate,
      now: now,
    );
  }

  /// Inserts a fresh `pending` ledger row — the manual branch of catch-up
  /// (HU-02) and [_ensureDuePendingOccurrence] both funnel through this
  /// instead of duplicating the companion construction.
  Future<db.ScheduledPaymentOccurrence> _insertPendingOccurrence({
    required String scheduledPaymentId,
    required DateTime occurrenceDate,
    required DateTime now,
  }) =>
      _local.insertOccurrence(
        ScheduledPaymentOccurrenceMapper.pendingInsertCompanion(
          scheduledPaymentId: scheduledPaymentId,
          occurrenceDate: occurrenceDate,
          now: now,
        ),
      );

  /// Generates the transaction a due/confirmed occurrence produces. `date`/
  /// `accountId`/`amountMinor` are the (possibly edited, HU-03) final
  /// values; `categoryId`/`note`/`currency`/`type`/`transferAccountId` are
  /// always read from the template as it stands right now (criterion 7/8 —
  /// never editable at confirmation time).
  Future<db.Transaction> _generateTransaction(
    db.ScheduledPayment template, {
    required DateTime date,
    required String accountId,
    required int amountMinor,
    required DateTime now,
  }) async {
    final companion = db.TransactionsCompanion.insert(
      accountId: accountId,
      categoryId: Value(template.categoryId),
      amountMinor: amountMinor,
      currency: template.currency,
      type: template.type,
      date: date,
      note: Value(template.note),
      source: const Value(db.TxSource.scheduled),
      transferAccountId: Value(template.transferAccountId),
      scheduledPaymentId: Value(template.id),
      createdAt: Value(now),
      updatedAt: Value(now.millisecondsSinceEpoch),
    );
    final generated = await _local.insertGeneratedTransaction(companion);
    await _local.copyTemplateTagsToTransaction(
      scheduledPaymentId: template.id,
      transactionId: generated.id,
      now: now,
    );
    return generated;
  }

  ScheduledPaymentSummary _toSummary(ScheduledPaymentRowWithJoins row) =>
      ScheduledPaymentSummary(
        scheduledPayment: ScheduledPaymentMapper.toEntity(row.scheduledPayment),
        accountName: row.account.name,
        categoryName: row.category?.name,
        categoryIcon: row.category?.icon,
        categoryColor: row.category?.color,
        transferAccountName: row.transferAccount?.name,
        pendingOccurrenceCount: row.pendingOccurrenceCount,
        nextAwaitingDate: row.nextAwaitingDate,
        lastPaymentDate: row.lastPaymentDate,
      );

  Tag _toTagEntity(db.Tag row) => Tag(
        id: row.id,
        name: row.name,
        color: row.color,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// Turns any infrastructure exception into a `Failure`, so nothing escapes
  /// the data layer as a raw exception.
  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      // Report so the failure is never silent: dev prints it (NoopCrashReporter
      // in debug), prod ships it to Sentry (SentryCrashReporter).
      await _crash.recordError(e, st, context: 'scheduled payments query');
      return Left(
        DatabaseFailure(
          'scheduled payments query failed',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Same for streams: a query error becomes a `Left` **emission** instead
  /// of a stream error, so the cubit can render the error state without the
  /// subscription dying.
  Stream<Result<T>> _guardStream<T>(Stream<Result<T>> source) =>
      source.transform(
        StreamTransformer<Result<T>, Result<T>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            // Same visibility as [_guard]: dev prints, prod ships to Sentry.
            unawaited(
              _crash.recordError(
                error,
                stackTrace,
                context: 'scheduled payments stream',
              ),
            );
            sink.add(
              Left(
                DatabaseFailure(
                  'scheduled payments stream failed',
                  cause: error,
                  stackTrace: stackTrace,
                ),
              ),
            );
          },
        ),
      );
}
