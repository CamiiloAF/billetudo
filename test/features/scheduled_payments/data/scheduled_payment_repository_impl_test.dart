import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/data/datasources/scheduled_payment_tags_local_datasource.dart';
import 'package:billetudo/features/scheduled_payments/data/datasources/scheduled_payments_local_datasource.dart';
import 'package:billetudo/features/scheduled_payments/data/repositories/scheduled_payment_repository_impl.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_history_entry.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart'
    as domain;
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_occurrence.dart'
    as domain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ScheduledPaymentRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ScheduledPaymentRepositoryImpl(
      ScheduledPaymentsLocalDatasource(database),
      ScheduledPaymentTagsLocalDatasource(database),
      const NoopCrashReporter(),
    );
  });

  tearDown(() async => database.close());

  Future<Account> createAccount(String name) =>
      database.into(database.accounts).insertReturning(
            AccountsCompanion.insert(
              name: name,
              type: AccountType.bank,
              currency: 'COP',
            ),
          );

  Future<Category> createCategory(String name, {required CategoryKind kind}) =>
      database.into(database.categories).insertReturning(
            CategoriesCompanion.insert(name: name, kind: kind),
          );

  late Account account;
  late Category expenseCategory;

  setUp(() async {
    account = await createAccount('Efectivo');
    expenseCategory = await createCategory('Renta', kind: CategoryKind.expense);
  });

  ScheduledPaymentDraft monthlyDraft({
    String? id,
    DateTime? nextDate,
    DateTime? endDate,
    bool requiresConfirmation = false,
    domain.ScheduledPaymentFrequency frequency =
        domain.ScheduledPaymentFrequency.monthly,
    List<String> tagIds = const <String>[],
  }) =>
      ScheduledPaymentDraft(
        id: id,
        accountId: account.id,
        categoryId: expenseCategory.id,
        amountMinor: 50000,
        currency: 'COP',
        type: domain.ScheduledPaymentType.expense,
        note: 'Arriendo',
        frequency: frequency,
        nextDate: nextDate ?? DateTime(2026, 7, 1),
        endDate: endDate,
        requiresConfirmation: requiresConfirmation,
        tagIds: tagIds,
      );

  Future<domain.ScheduledPayment> createTemplate(
    ScheduledPaymentDraft draft,
  ) async {
    final result = await repository.createScheduledPayment(draft);
    return result.getRight().toNullable()!;
  }

  Future<ScheduledPayment> rowOf(String id) =>
      (database.select(database.scheduledPayments)
            ..where((s) => s.id.equals(id)))
          .getSingle();

  group('createScheduledPayment (HU-01)', () {
    test('persiste todos los campos requeridos por el criterio 1', () async {
      final tag = await database
          .into(database.tags)
          .insertReturning(TagsCompanion.insert(name: 'hogar'));
      final template = await createTemplate(
        monthlyDraft(tagIds: [tag.id]),
      );

      final row = await rowOf(template.id);
      expect(row.accountId, account.id);
      expect(row.categoryId, expenseCategory.id);
      expect(row.amountMinor, 50000);
      expect(row.currency, 'COP');
      expect(row.type, EntryType.expense);
      expect(row.frequency, ScheduleFrequency.monthly);
      expect(row.nextDate, DateTime(2026, 7, 1));
      expect(row.requiresConfirmation, isFalse);
      expect(row.tombstonedAt, isNull);

      final links = await (database.select(database.scheduledPaymentTags)
            ..where((t) => t.scheduledPaymentId.equals(template.id)))
          .get();
      expect(links.single.tagId, tag.id);
    });

    test('criterio 16: una transferencia nunca guarda etiquetas', () async {
      final otherAccount = await createAccount('Banco');
      final tag = await database
          .into(database.tags)
          .insertReturning(TagsCompanion.insert(name: 'viaje'));

      final draft = ScheduledPaymentDraft(
        accountId: account.id,
        transferAccountId: otherAccount.id,
        amountMinor: 20000,
        currency: 'COP',
        type: domain.ScheduledPaymentType.transfer,
        frequency: domain.ScheduledPaymentFrequency.once,
        nextDate: DateTime(2026, 7, 1),
        tagIds: [tag.id],
      );

      final template = await createTemplate(draft);

      final links = await (database.select(database.scheduledPaymentTags)
            ..where((t) => t.scheduledPaymentId.equals(template.id)))
          .get();
      expect(links, isEmpty);
    });
  });

  group('updateScheduledPayment (HU-05)', () {
    test('no toca transacciones ya generadas (criterio 12)', () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 7, 1)),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 1),
      );
      final generatedBefore =
          await database.select(database.transactions).get();
      expect(generatedBefore, hasLength(1));
      final originalAmount = generatedBefore.single.amountMinor;

      await repository.updateScheduledPayment(
        monthlyDraft(id: template.id, nextDate: DateTime(2026, 8, 1))
            .copyWithAmount(99999),
      );

      final generatedAfter = await database.select(database.transactions).get();
      expect(generatedAfter.single.amountMinor, originalAmount);
    });

    test('editar una plantilla inexistente es NotFound', () async {
      final result = await repository.updateScheduledPayment(
        monthlyDraft(id: 'no-existe'),
      );

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('deleteScheduledPayment (HU-05)', () {
    test('borra vía tombstonedAt y preserva la referencia histórica', () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 7, 1)),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 1),
      );

      final result = await repository.deleteScheduledPayment(template.id);

      expect(result.isRight(), isTrue);
      final row = await rowOf(template.id);
      expect(row.tombstonedAt, isNotNull);

      final generated = await database.select(database.transactions).get();
      expect(generated.single.scheduledPaymentId, template.id);
    });

    test('una plantilla ya borrada no puede editarse', () async {
      final template = await createTemplate(monthlyDraft());
      await repository.deleteScheduledPayment(template.id);

      final result = await repository.updateScheduledPayment(
        monthlyDraft(id: template.id),
      );

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('watchActiveScheduledPayments (HU-04)', () {
    test('ordena por nextDate ascendente', () async {
      await createTemplate(monthlyDraft(nextDate: DateTime(2026, 8, 1)));
      final earlier =
          await createTemplate(monthlyDraft(nextDate: DateTime(2026, 7, 1)));

      final result = await repository.watchActiveScheduledPayments().first;

      final ids =
          result.getRight().toNullable()!.map((s) => s.scheduledPayment.id);
      expect(ids.first, earlier.id);
    });

    test('excluye una plantilla borrada', () async {
      final template = await createTemplate(monthlyDraft());
      await repository.deleteScheduledPayment(template.id);

      final result = await repository.watchActiveScheduledPayments().first;

      expect(result.getRight().toNullable(), isEmpty);
    });

    test(
        'criterio 4: una plantilla once queda inactiva tras generar su única '
        'ocurrencia', () async {
      final template = await createTemplate(
        monthlyDraft(
          frequency: domain.ScheduledPaymentFrequency.once,
          nextDate: DateTime(2026, 7, 1),
        ),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 1),
      );

      final result = await repository.watchActiveScheduledPayments().first;

      expect(
        result
            .getRight()
            .toNullable()!
            .map((s) => s.scheduledPayment.id)
            .contains(template.id),
        isFalse,
      );
    });

    test('criterio 4: una plantilla deja de generar tras alcanzar endDate',
        () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 1),
        ),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 9, 1),
      );

      final result = await repository.watchActiveScheduledPayments().first;

      expect(
        result
            .getRight()
            .toNullable()!
            .map((s) => s.scheduledPayment.id)
            .contains(template.id),
        isFalse,
      );
      // Sigue viva, solo dejó de generar (no se borró).
      final row = await rowOf(template.id);
      expect(row.tombstonedAt, isNull);
    });

    test(
        'criterio 11: una plantilla con pendiente aparece una sola vez, con '
        'el conteo', () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 7, 1),
          requiresConfirmation: true,
        ),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 1),
      );

      final result = await repository.watchActiveScheduledPayments().first;
      final summaries = result.getRight().toNullable()!;

      expect(
        summaries.where((s) => s.scheduledPayment.id == template.id),
        hasLength(1),
      );
      expect(
        summaries
            .firstWhere((s) => s.scheduledPayment.id == template.id)
            .pendingOccurrenceCount,
        1,
      );
    });
  });

  group('generateDueScheduledPayments (HU-02)', () {
    test('modo automático genera la transacción y copia las etiquetas',
        () async {
      final tag = await database
          .into(database.tags)
          .insertReturning(TagsCompanion.insert(name: 'hogar'));
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 7, 1), tagIds: [tag.id]),
      );

      final result = await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 1),
      );

      expect(result.isRight(), isTrue);
      final generated = await database.select(database.transactions).get();
      expect(generated, hasLength(1));
      expect(generated.single.source, TxSource.scheduled);
      expect(generated.single.scheduledPaymentId, template.id);

      final tagLinks = await (database.select(database.transactionTags)
            ..where((t) => t.transactionId.equals(generated.single.id)))
          .get();
      expect(tagLinks.single.tagId, tag.id);

      // Avanza nextDate (repetible).
      final row = await rowOf(template.id);
      expect(row.nextDate, DateTime(2026, 8, 1));
    });

    test('modo manual acumula pendientes sin afectar el saldo (criterio 6)',
        () async {
      await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 7, 1),
          requiresConfirmation: true,
        ),
      );

      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 1),
      );

      final generated = await database.select(database.transactions).get();
      expect(generated, isEmpty);
      final occurrences =
          await database.select(database.scheduledPaymentOccurrences).get();
      expect(occurrences.single.status, ScheduledOccurrenceStatus.pending);
    });

    test(
        'criterio 5 (modo manual): varias ocurrencias vencidas tras estar '
        'cerrada se listan todas como pendientes acumuladas (chip ×N), sin '
        'perder ninguna ni afectar el saldo', () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 5, 1),
          requiresConfirmation: true,
        ),
      );

      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 15),
      );

      final generated = await database.select(database.transactions).get();
      expect(generated, isEmpty);

      final occurrences = await (database.select(
        database.scheduledPaymentOccurrences,
      )..where((o) => o.scheduledPaymentId.equals(template.id)))
          .get();
      // Mayo, junio y julio: 3 ocurrencias vencidas, todas pendientes.
      expect(occurrences, hasLength(3));
      expect(
        occurrences.every((o) => o.status == ScheduledOccurrenceStatus.pending),
        isTrue,
      );

      // Un segundo catch-up en el mismo instante no duplica.
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 15),
      );
      final afterSecondRun = await (database.select(
        database.scheduledPaymentOccurrences,
      )..where((o) => o.scheduledPaymentId.equals(template.id)))
          .get();
      expect(afterSecondRun, hasLength(3));
    });

    test(
        'criterio 5: varias ocurrencias vencidas tras estar cerrada se '
        'generan todas sin duplicar', () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 5, 1)),
      );

      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 15),
      );

      final generated = await (database.select(database.transactions)
            ..where((t) => t.scheduledPaymentId.equals(template.id)))
          .get();
      // Mayo, junio y julio: 3 ocurrencias vencidas.
      expect(generated, hasLength(3));

      // Un segundo catch-up en el mismo instante no duplica.
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 15),
      );
      final afterSecondRun = await (database.select(database.transactions)
            ..where((t) => t.scheduledPaymentId.equals(template.id)))
          .get();
      expect(afterSecondRun, hasLength(3));
    });
  });

  group('confirmOccurrence / skipOccurrence (HU-03)', () {
    Future<ScheduledPaymentOccurrence> pendingOccurrenceFor(
      String templateId,
    ) =>
        (database.select(database.scheduledPaymentOccurrences)
              ..where((o) => o.scheduledPaymentId.equals(templateId)))
            .getSingle();

    test('confirmar aplica los valores editados sin mutar la plantilla',
        () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 7, 1),
          requiresConfirmation: true,
        ),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 1),
      );
      final occurrence = await pendingOccurrenceFor(template.id);
      final otherAccount = await createAccount('Banco');

      final result = await repository.confirmOccurrence(
        occurrenceId: occurrence.id,
        date: DateTime(2026, 7, 2),
        accountId: otherAccount.id,
        amountMinor: 60000,
      );

      expect(result.isRight(), isTrue);
      final tx = result.getRight().toNullable()!;
      expect(tx.accountId, otherAccount.id);
      expect(tx.amountMinor, 60000);
      expect(tx.date, DateTime(2026, 7, 2));

      // La plantilla queda intacta.
      final templateRow = await rowOf(template.id);
      expect(templateRow.accountId, account.id);
      expect(templateRow.amountMinor, 50000);
    });

    test('omitir descarta sin generar transacción y es reversible', () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 7, 1),
          requiresConfirmation: true,
        ),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 1),
      );
      final occurrence = await pendingOccurrenceFor(template.id);

      final skipResult = await repository.skipOccurrence(occurrence.id);
      expect(skipResult.isRight(), isTrue);
      var row = await (database.select(database.scheduledPaymentOccurrences)
            ..where((o) => o.id.equals(occurrence.id)))
          .getSingle();
      expect(row.status, ScheduledOccurrenceStatus.skipped);
      expect(await database.select(database.transactions).get(), isEmpty);

      final undoResult = await repository.undoSkipOccurrence(occurrence.id);
      expect(undoResult.isRight(), isTrue);
      row = await (database.select(database.scheduledPaymentOccurrences)
            ..where((o) => o.id.equals(occurrence.id)))
          .getSingle();
      expect(row.status, ScheduledOccurrenceStatus.pending);
    });
  });

  group('snoozeOccurrence / undoSnoozeOccurrence (HU-07)', () {
    test('mueve solo la ocurrencia sin tocar la cadencia de la plantilla',
        () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 7, 1)),
      );

      final result = await repository.snoozeOccurrence(
        scheduledPaymentId: template.id,
        occurrenceDate: DateTime(2026, 7, 1),
        newDate: DateTime(2026, 7, 10),
      );

      expect(result.isRight(), isTrue);
      final outcome = result.getRight().toNullable()!;
      expect(
        outcome.occurrence.status,
        domain.ScheduledOccurrenceStatus.snoozed,
      );
      expect(outcome.occurrence.snoozedToDate, DateTime(2026, 7, 10));
      // A brand-new occurrence: nothing existed at 2026-07-01 before.
      expect(outcome.wasCreated, isTrue);
      expect(outcome.previousSnoozedToDate, isNull);

      final templateRow = await rowOf(template.id);
      expect(templateRow.nextDate, DateTime(2026, 7, 1));
    });

    test(
        'deshacer un posponer de un pago aún no vencido borra el registro '
        'en vez de dejarlo pendiente antes de tiempo', () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 8, 1)),
      );
      final snoozeResult = await repository.snoozeOccurrence(
        scheduledPaymentId: template.id,
        occurrenceDate: DateTime(2026, 8, 1),
        newDate: DateTime(2026, 8, 10),
      );
      final outcome = snoozeResult.getRight().toNullable()!;
      expect(outcome.wasCreated, isTrue);
      final occurrenceId = outcome.occurrence.id;

      final undoResult = await repository.undoSnoozeOccurrence(
        occurrenceId,
        wasCreated: true,
      );

      expect(undoResult.isRight(), isTrue);
      final remaining =
          await database.select(database.scheduledPaymentOccurrences).get();
      expect(remaining, isEmpty);
    });

    test(
        'deshacer un re-posponer restaura la fecha del snooze anterior '
        '(23 -> 30 -> 31 -> undo = 30), un solo paso', () async {
      // A due occurrence already exists (nextDate in the past), so the first
      // snooze mutates an existing row rather than materializing a new one.
      // Manual mode so the due occurrence materializes as `pending` (awaiting)
      // instead of being auto-confirmed.
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 3, 23),
          requiresConfirmation: true,
        ),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 3, 25),
      );

      final first = await repository.snoozeOccurrence(
        scheduledPaymentId: template.id,
        occurrenceDate: DateTime(2026, 3, 23),
        newDate: DateTime(2026, 3, 30),
      );
      final firstOutcome = first.getRight().toNullable()!;
      // Pre-existing due occurrence, not materialized here.
      expect(firstOutcome.wasCreated, isFalse);
      expect(firstOutcome.previousSnoozedToDate, isNull);
      final occurrenceId = firstOutcome.occurrence.id;

      // The occurrence keeps its original date as identity; a re-snooze moves
      // its snoozedToDate again, so it addresses the same 2026-03-23 row.
      final second = await repository.snoozeOccurrence(
        scheduledPaymentId: template.id,
        occurrenceDate: DateTime(2026, 3, 23),
        newDate: DateTime(2026, 3, 31),
      );
      final secondOutcome = second.getRight().toNullable()!;
      expect(secondOutcome.wasCreated, isFalse);
      // The re-snooze must remember the date the row held right before it.
      expect(secondOutcome.previousSnoozedToDate, DateTime(2026, 3, 30));

      // Undo the re-snooze: it reverses ONE step, back to 2026-03-30.
      final undo = await repository.undoSnoozeOccurrence(
        occurrenceId,
        wasCreated: false,
        previousSnoozedToDate: DateTime(2026, 3, 30),
      );
      expect(undo.isRight(), isTrue);

      final row = await (database.select(database.scheduledPaymentOccurrences)
            ..where((o) => o.id.equals(occurrenceId)))
          .getSingle();
      expect(row.status, ScheduledOccurrenceStatus.snoozed);
      expect(row.snoozedToDate, DateTime(2026, 3, 30));
    });

    test(
        'deshacer el primer posponer de una ocurrencia vencida la vuelve a '
        'pending (sin fecha previa)', () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 3, 23),
          requiresConfirmation: true,
        ),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 3, 25),
      );

      final first = await repository.snoozeOccurrence(
        scheduledPaymentId: template.id,
        occurrenceDate: DateTime(2026, 3, 23),
        newDate: DateTime(2026, 3, 30),
      );
      final occurrenceId = first.getRight().toNullable()!.occurrence.id;

      final undo = await repository.undoSnoozeOccurrence(
        occurrenceId,
        wasCreated: false,
      );
      expect(undo.isRight(), isTrue);

      final row = await (database.select(database.scheduledPaymentOccurrences)
            ..where((o) => o.id.equals(occurrenceId)))
          .getSingle();
      expect(row.status, ScheduledOccurrenceStatus.pending);
      expect(row.snoozedToDate, isNull);
    });
  });

  group('watchScheduledPaymentDetail / history (criterio 13)', () {
    test('expone la primera página y el conteo total del historial', () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 1, 1)),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 5, 1),
      );

      final result =
          await repository.watchScheduledPaymentDetail(template.id).first;

      final detail = result.getRight().toNullable()!;
      expect(detail.historyTotalCount, 5);
      expect(detail.history, hasLength(3));
    });

    test('getScheduledPaymentHistory pagina "cargar más"', () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 1, 1)),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 5, 1),
      );

      final result = await repository.getScheduledPaymentHistory(
        template.id,
        offset: 3,
        limit: 3,
      );

      expect(result.getRight().toNullable(), hasLength(2));
    });

    test('una plantilla inexistente es NotFound', () async {
      final result =
          await repository.watchScheduledPaymentDetail('no-existe').first;

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('historial combinado con omitidos (page spec)', () {
    Future<List<ScheduledPaymentOccurrence>> occurrencesOf(String id) async {
      final rows = await (database.select(database.scheduledPaymentOccurrences)
            ..where((o) => o.scheduledPaymentId.equals(id)))
          .get();
      rows.sort((a, b) => a.occurrenceDate.compareTo(b.occurrenceDate));
      return rows;
    }

    // Manual template, catch-up materializes 5 pending (Jan..May); confirm the
    // two oldest (→ transactions), skip the next two (→ skipped), leave May
    // pending. History = 2 confirmed + 2 skipped, interleaved by effective
    // date desc; the pending one never shows.
    Future<domain.ScheduledPayment> seedMixedHistory() async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 1, 1), requiresConfirmation: true),
      );
      await repository.generateDueScheduledPayments(now: DateTime(2026, 5, 1));
      final occ = await occurrencesOf(template.id);
      for (final index in [0, 1]) {
        final confirmed = await repository.confirmOccurrence(
          occurrenceId: occ[index].id,
          date: occ[index].occurrenceDate,
          accountId: account.id,
          amountMinor: 50000,
        );
        expect(confirmed.isRight(), isTrue);
      }
      for (final index in [2, 3]) {
        expect(
          (await repository.skipOccurrence(occ[index].id)).isRight(),
          isTrue,
        );
      }
      return template;
    }

    test('conteo total suma confirmados y omitidos, sin el pendiente',
        () async {
      final template = await seedMixedHistory();

      final detail =
          (await repository.watchScheduledPaymentDetail(template.id).first)
              .getRight()
              .toNullable()!;

      expect(detail.historyTotalCount, 4);
      expect(detail.generatedTransactionCount, 2);
    });

    test('la primera página intercala por fecha efectiva, más reciente arriba',
        () async {
      final template = await seedMixedHistory();

      final detail =
          (await repository.watchScheduledPaymentDetail(template.id).first)
              .getRight()
              .toNullable()!;

      // Abr(omitido) · Mar(omitido) · Feb(confirmado): 3 filas.
      expect(detail.history, hasLength(3));
      final first = detail.history[0];
      expect(first, isA<ScheduledSkippedHistoryEntry>());
      first as ScheduledSkippedHistoryEntry;
      expect(first.date, DateTime(2026, 4, 1));
      // El monto del omitido es el de la plantilla al momento.
      expect(first.amountMinor, 50000);
      expect(detail.history[1], isA<ScheduledSkippedHistoryEntry>());
      expect(detail.history[2], isA<ScheduledConfirmedHistoryEntry>());
    });

    test('"cargar más" pagina sobre ambas fuentes', () async {
      final template = await seedMixedHistory();

      final page = (await repository.getScheduledPaymentHistory(
        template.id,
        offset: 3,
        limit: 3,
      ))
          .getRight()
          .toNullable()!;

      // La cuarta (y última) entrada: Ene, confirmada.
      expect(page, hasLength(1));
      expect(page.single, isA<ScheduledConfirmedHistoryEntry>());
    });
  });

  group(
      'watchScheduledPaymentDetail materializa pendiente bajo demanda '
      '(modo automático, fix)', () {
    test(
        'plantilla automática vencida sin fila materializa una ocurrencia '
        'pending', () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 7, 1)),
      );

      final result = await repository
          .watchScheduledPaymentDetail(template.id)
          .first;

      final detail = result.getRight().toNullable()!;
      expect(detail.pendingOccurrence, isNotNull);
      expect(
        detail.pendingOccurrence!.occurrence.status,
        domain.ScheduledOccurrenceStatus.pending,
      );
      expect(
        detail.pendingOccurrence!.occurrence.occurrenceDate,
        DateTime(2026, 7, 1),
      );
      final occurrences =
          await database.select(database.scheduledPaymentOccurrences).get();
      expect(occurrences.single.scheduledPaymentId, template.id);
      expect(occurrences.single.status, ScheduledOccurrenceStatus.pending);
      // La plantilla queda intacta: es una materialización de la ocurrencia,
      // no una generación (eso solo lo hace generateDueScheduledPayments).
      final generated = await database.select(database.transactions).get();
      expect(generated, isEmpty);
    });

    test('cursor futuro no materializa nada', () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 12, 1)),
      );

      final result = await repository
          .watchScheduledPaymentDetail(template.id)
          .first;

      expect(result.getRight().toNullable()!.pendingOccurrence, isNull);
      expect(
        await database.select(database.scheduledPaymentOccurrences).get(),
        isEmpty,
      );
    });

    test('no duplica si ya hay una fila para esa fecha exacta', () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 7, 1)),
      );

      await repository.watchScheduledPaymentDetail(template.id).first;
      await repository.watchScheduledPaymentDetail(template.id).first;

      final occurrences = await (database.select(
        database.scheduledPaymentOccurrences,
      )..where((o) => o.scheduledPaymentId.equals(template.id)))
          .get();
      expect(occurrences, hasLength(1));
    });

    test('respeta endDate: no materializa pasado el fin de la plantilla',
        () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 6, 1),
        ),
      );

      final result = await repository
          .watchScheduledPaymentDetail(template.id)
          .first;

      expect(result.getRight().toNullable()!.pendingOccurrence, isNull);
      expect(
        await database.select(database.scheduledPaymentOccurrences).get(),
        isEmpty,
      );
    });

    test('una plantilla borrada (tombstonedAt) no materializa nada',
        () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 7, 1)),
      );
      await repository.deleteScheduledPayment(template.id);

      final result = await repository
          .watchScheduledPaymentDetail(template.id)
          .first;

      expect(result.getRight().toNullable()!.pendingOccurrence, isNull);
      expect(
        await database.select(database.scheduledPaymentOccurrences).get(),
        isEmpty,
      );
    });
  });

  group(
      'advanceScheduledOccurrence (HU-05 "Confirmar ahora", '
      'docs/bugfixes.md point 1)', () {
    test(
        'plantilla automática con nextDate futuro materializa una ocurrencia '
        'pending forzada, sin generar transacción', () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 12, 1)),
      );

      final result =
          await repository.advanceScheduledOccurrence(template.id);

      expect(result.isRight(), isTrue);
      final pending = result.getRight().toNullable()!;
      expect(
        pending.occurrence.status,
        domain.ScheduledOccurrenceStatus.pending,
      );
      expect(pending.occurrence.occurrenceDate, DateTime(2026, 12, 1));
      expect(pending.scheduledPayment.id, template.id);

      final occurrences =
          await database.select(database.scheduledPaymentOccurrences).get();
      expect(occurrences.single.scheduledPaymentId, template.id);
      expect(occurrences.single.status, ScheduledOccurrenceStatus.pending);
      // No mueve dinero: solo materializa la ocurrencia a confirmar.
      expect(await database.select(database.transactions).get(), isEmpty);
      // El cursor NO se mueve al abrir el sheet: materializar la ocurrencia
      // especulativa no debe avanzar `nextDate` (solo confirmar/omitir lo hace).
      final templateRow = await rowOf(template.id);
      expect(templateRow.nextDate, DateTime(2026, 12, 1));
    });

    test(
        'confirmar ahora y CONFIRMAR la ocurrencia avanza el próximo pago al '
        'siguiente ciclo, no lo deja atascado en la fecha ya generada',
        () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 7, 21),
          requiresConfirmation: true,
        ),
      );

      final advanced = await repository.advanceScheduledOccurrence(template.id);
      final pending = advanced.getRight().toNullable()!;
      final confirm = await repository.confirmOccurrence(
        occurrenceId: pending.occurrence.id,
        date: pending.occurrence.occurrenceDate,
        accountId: template.accountId,
        amountMinor: template.amountMinor,
      );

      expect(confirm.isRight(), isTrue);
      // El próximo pago avanzó a agosto; no se queda en el 21 de julio ya
      // generado (el bug que veía el usuario en el detalle).
      final templateRow = await rowOf(template.id);
      expect(templateRow.nextDate, DateTime(2026, 8, 21));
      final occurrences = await (database.select(
        database.scheduledPaymentOccurrences,
      )..where((o) => o.scheduledPaymentId.equals(template.id)))
          .get();
      expect(occurrences, hasLength(1));
      expect(occurrences.single.status, ScheduledOccurrenceStatus.confirmed);
    });

    test(
        'confirmar ahora y DESCARTAR (cerrar sin confirmar) borra la ocurrencia '
        'especulativa y deja el próximo pago intacto', () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 7, 21),
          requiresConfirmation: true,
        ),
      );

      final advanced = await repository.advanceScheduledOccurrence(template.id);
      final pending = advanced.getRight().toNullable()!;
      final discard = await repository
          .discardUnconfirmedAdvanceOccurrence(pending.occurrence.id);

      expect(discard.isRight(), isTrue);
      // El cursor no se movió y no quedó ninguna ocurrencia fantasma.
      final templateRow = await rowOf(template.id);
      expect(templateRow.nextDate, DateTime(2026, 7, 21));
      final occurrences = await (database.select(
        database.scheduledPaymentOccurrences,
      )..where((o) => o.scheduledPaymentId.equals(template.id)))
          .get();
      expect(occurrences, isEmpty);
    });

    test(
        'descartar NO borra una ocurrencia ya confirmada ni una de catch-up '
        'legítima (anterior al cursor)', () async {
      await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 7, 21),
          requiresConfirmation: true,
        ),
      );
      // Ocurrencia de catch-up: vencida y anterior al cursor tras avanzar.
      await repository.generateDueScheduledPayments(now: DateTime(2026, 7, 21));
      final catchUp =
          await database.select(database.scheduledPaymentOccurrences).get();
      expect(catchUp, hasLength(1));

      final discard = await repository
          .discardUnconfirmedAdvanceOccurrence(catchUp.single.id);

      expect(discard.isRight(), isTrue);
      // La ocurrencia de catch-up sobrevive: no es especulativa.
      final after =
          await database.select(database.scheduledPaymentOccurrences).get();
      expect(after, hasLength(1));
    });

    test(
        'plantilla en modo manual también materializa una ocurrencia pending '
        'forzada (confirmar ahora aplica a cualquier modo)', () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 12, 1),
          requiresConfirmation: true,
        ),
      );

      final result =
          await repository.advanceScheduledOccurrence(template.id);

      expect(result.isRight(), isTrue);
      final pending = result.getRight().toNullable()!;
      expect(
        pending.occurrence.status,
        domain.ScheduledOccurrenceStatus.pending,
      );
      expect(pending.occurrence.occurrenceDate, DateTime(2026, 12, 1));
      // No mueve dinero: solo materializa la ocurrencia a confirmar.
      expect(await database.select(database.transactions).get(), isEmpty);
      final occurrences =
          await database.select(database.scheduledPaymentOccurrences).get();
      expect(occurrences.single.status, ScheduledOccurrenceStatus.pending);
    });

    test('plantilla borrada (tombstonedAt) sigue bloqueando aun con force',
        () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 12, 1)),
      );
      await repository.deleteScheduledPayment(template.id);

      final result =
          await repository.advanceScheduledOccurrence(template.id);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(
        await database.select(database.scheduledPaymentOccurrences).get(),
        isEmpty,
      );
    });

    test('plantilla con endDate ya vencido sigue bloqueando aun con force',
        () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 12, 1),
          endDate: DateTime(2026, 11, 1),
        ),
      );

      final result =
          await repository.advanceScheduledOccurrence(template.id);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(
        await database.select(database.scheduledPaymentOccurrences).get(),
        isEmpty,
      );
    });

    test(
        'plantilla once ya confirmada (nada que confirmar) sigue bloqueando '
        'aun con force', () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 7, 1),
          frequency: domain.ScheduledPaymentFrequency.once,
        ),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 7, 1),
      );

      final result =
          await repository.advanceScheduledOccurrence(template.id);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      // No agrega una segunda ocurrencia junto a la ya confirmada.
      final occurrences = await (database.select(
        database.scheduledPaymentOccurrences,
      )..where((o) => o.scheduledPaymentId.equals(template.id)))
          .get();
      expect(occurrences, hasLength(1));
      expect(occurrences.single.status, ScheduledOccurrenceStatus.confirmed);
    });

    test('llamar dos veces seguidas reutiliza la misma ocurrencia, sin duplicar',
        () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 12, 1)),
      );

      final first = await repository.advanceScheduledOccurrence(template.id);
      final second = await repository.advanceScheduledOccurrence(template.id);

      expect(
        first.getRight().toNullable()!.occurrence.id,
        second.getRight().toNullable()!.occurrence.id,
      );
      final occurrences =
          await database.select(database.scheduledPaymentOccurrences).get();
      expect(occurrences, hasLength(1));
    });

    test('plantilla inexistente es NotFound', () async {
      final result = await repository.advanceScheduledOccurrence('no-existe');

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('watchFinishedScheduledPayments (filtro "Terminados")', () {
    test(
        'expone la fecha del último pago realmente generado, no la de fin '
        'de la plantilla', () async {
      final template = await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 3, 31),
        ),
      );
      // Modo automático: la puesta al día confirma cada vencimiento hasta
      // que la plantilla pasa su endDate y deja de generar.
      await repository.generateDueScheduledPayments(now: DateTime(2026, 4, 1));

      final result = await repository.watchFinishedScheduledPayments().first;
      final items = result.getRight().toNullable()!;

      expect(items, hasLength(1));
      expect(items.single.scheduledPayment.id, template.id);
      expect(items.single.lastPaymentDate, DateTime(2026, 3, 15));
    });

    test('sin pagos generados no hay fecha que mostrar', () async {
      await createTemplate(
        monthlyDraft(
          nextDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 4, 1),
        ),
      );

      final result = await repository.watchFinishedScheduledPayments().first;
      final items = result.getRight().toNullable()!;

      expect(items, hasLength(1));
      expect(items.single.lastPaymentDate, isNull);
    });
  });
}

extension on ScheduledPaymentDraft {
  ScheduledPaymentDraft copyWithAmount(int amountMinor) =>
      ScheduledPaymentDraft(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        categoryKind: categoryKind,
        amountMinor: amountMinor,
        currency: currency,
        type: type,
        note: note,
        transferAccountId: transferAccountId,
        frequency: frequency,
        interval: interval,
        nextDate: nextDate,
        endDate: endDate,
        requiresConfirmation: requiresConfirmation,
        tagIds: tagIds,
      );
}
