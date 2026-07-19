import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/data/datasources/scheduled_payment_tags_local_datasource.dart';
import 'package:billetudo/features/scheduled_payments/data/datasources/scheduled_payments_local_datasource.dart';
import 'package:billetudo/features/scheduled_payments/data/repositories/scheduled_payment_repository_impl.dart';
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
    expenseCategory =
        await createCategory('Renta', kind: CategoryKind.expense);
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

      final generatedAfter =
          await database.select(database.transactions).get();
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
    test('borra vía tombstonedAt y preserva la referencia histórica',
        () async {
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
        summaries.firstWhere((s) => s.scheduledPayment.id == template.id)
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

    test('omitir descarta sin generar transacción y es reversible',
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
      final occurrence = result.getRight().toNullable()!;
      expect(occurrence.status, domain.ScheduledOccurrenceStatus.snoozed);
      expect(occurrence.snoozedToDate, DateTime(2026, 7, 10));

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
      final occurrenceId = snoozeResult.getRight().toNullable()!.id;

      final undoResult =
          await repository.undoSnoozeOccurrence(occurrenceId);

      expect(undoResult.isRight(), isTrue);
      final remaining =
          await database.select(database.scheduledPaymentOccurrences).get();
      expect(remaining, isEmpty);
    });
  });

  group('watchScheduledPaymentDetail / history (criterio 13)', () {
    test('expone la primera página y el conteo total del historial',
        () async {
      final template = await createTemplate(
        monthlyDraft(nextDate: DateTime(2026, 1, 1)),
      );
      await repository.generateDueScheduledPayments(
        now: DateTime(2026, 5, 1),
      );

      final result = await repository
          .watchScheduledPaymentDetail(template.id)
          .first;

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
}

extension on ScheduledPaymentDraft {
  ScheduledPaymentDraft copyWithAmount(int amountMinor) => ScheduledPaymentDraft(
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
