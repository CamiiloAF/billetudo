import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/repositories/account_repository.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/scheduled_payments/data/datasources/scheduled_payment_tags_local_datasource.dart';
import 'package:billetudo/features/scheduled_payments/data/datasources/scheduled_payments_local_datasource.dart';
import 'package:billetudo/features/scheduled_payments/data/repositories/scheduled_payment_repository_impl.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart'
    as d;
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/create_scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/delete_scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payment_detail.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/set_scheduled_payment_tags.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/update_scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The edit form never reads accounts (that branch is create-only), so a
/// no-op account repository is enough to build the cubit for these edit tests.
class _EmptyAccountRepository implements AccountRepository {
  @override
  Stream<Result<List<AccountWithBalance>>> watchActiveAccounts() =>
      const Stream<Result<List<AccountWithBalance>>>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

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

  ScheduledPaymentFormCubit buildFormCubit() => ScheduledPaymentFormCubit(
        CreateScheduledPayment(repository),
        UpdateScheduledPayment(repository),
        GetScheduledPaymentDetail(repository),
        SetScheduledPaymentTags(repository),
        DeleteScheduledPayment(repository),
        WatchAccounts(_EmptyAccountRepository()),
      );

  test(
      'item 18 (regresión): editar la fecha de un PP que vence hoy vía el '
      'formulario persiste, la muestra en el detalle Y sigue reflejada al '
      'reabrir el formulario', () async {
    final account = await database.into(database.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Efectivo',
            type: AccountType.bank,
            currency: 'COP',
          ),
        );
    final category = await database.into(database.categories).insertReturning(
          CategoriesCompanion.insert(name: 'Renta', kind: CategoryKind.expense),
        );

    // PP mensual manual con primer pago 10-jul.
    final created = await repository.createScheduledPayment(
      ScheduledPaymentDraft(
        accountId: account.id,
        categoryId: category.id,
        amountMinor: 50000,
        currency: 'COP',
        type: d.ScheduledPaymentType.expense,
        note: 'Arriendo',
        frequency: d.ScheduledPaymentFrequency.monthly,
        nextDate: DateTime(2026, 7, 10),
        requiresConfirmation: true,
        tagIds: const [],
      ),
    );
    final id = created.getRight().toNullable()!.id;

    // "Vence hoy": el catch-up materializa la ocurrencia pendiente del 10-jul y
    // avanza el cursor un mes (10-ago), dejando el ancla "Primer pago" en 10-jul.
    await repository.generateDueScheduledPayments(now: DateTime(2026, 7, 10));

    // El usuario abre el formulario y mueve la fecha al 20-jul.
    final cubit = buildFormCubit();
    await cubit.load(id);
    expect(cubit.state.nextDate, DateTime(2026, 7, 10)); // muestra el ancla
    cubit.nextDateChanged(DateTime(2026, 7, 20));
    await cubit.submit();
    expect(cubit.state.status, ScheduledPaymentFormStatus.saved);
    await cubit.close();

    // (a) El nextDate nuevo se persiste.
    final row = await (database.select(database.scheduledPayments)
          ..where((s) => s.id.equals(id)))
        .getSingle();
    expect(row.nextDate, DateTime(2026, 7, 20));
    // El ancla se reancla al nuevo pago, así que el formulario podrá mostrarlo.
    expect(row.firstPaymentDate, DateTime(2026, 7, 20));

    // (c) No queda una ocurrencia pendiente vieja re-pisando la fecha.
    final occurrences =
        await (database.select(database.scheduledPaymentOccurrences)
              ..where((o) => o.scheduledPaymentId.equals(id)))
            .get();
    expect(occurrences, isEmpty);

    // (b) El detalle/hero muestra la fecha nueva.
    final detail = (await repository.watchScheduledPaymentDetail(id).first)
        .getRight()
        .toNullable()!;
    expect(detail.nextPaymentDate, DateTime(2026, 7, 20));

    // El bug original: al reabrir el formulario la fecha nueva SÍ se refleja
    // (antes mostraba el firstPaymentDate viejo del 10-jul).
    final reopened = buildFormCubit();
    await reopened.load(id);
    expect(reopened.state.nextDate, DateTime(2026, 7, 20));
    await reopened.close();
  });

  test(
      'item 18: editar sin tocar la fecha NO reancla el ancla ni borra la '
      'ocurrencia pendiente que vence hoy', () async {
    final account = await database.into(database.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Efectivo',
            type: AccountType.bank,
            currency: 'COP',
          ),
        );
    final category = await database.into(database.categories).insertReturning(
          CategoriesCompanion.insert(name: 'Renta', kind: CategoryKind.expense),
        );
    final created = await repository.createScheduledPayment(
      ScheduledPaymentDraft(
        accountId: account.id,
        categoryId: category.id,
        amountMinor: 50000,
        currency: 'COP',
        type: d.ScheduledPaymentType.expense,
        note: 'Arriendo',
        frequency: d.ScheduledPaymentFrequency.monthly,
        nextDate: DateTime(2026, 7, 10),
        requiresConfirmation: true,
        tagIds: const [],
      ),
    );
    final id = created.getRight().toNullable()!.id;
    await repository.generateDueScheduledPayments(now: DateTime(2026, 7, 10));

    final cubit = buildFormCubit();
    await cubit.load(id);
    cubit.noteChanged('Arriendo actualizado'); // no toca la fecha
    await cubit.submit();
    expect(cubit.state.status, ScheduledPaymentFormStatus.saved);
    await cubit.close();

    final row = await (database.select(database.scheduledPayments)
          ..where((s) => s.id.equals(id)))
        .getSingle();
    // El ancla y el cursor quedan como estaban (el catch-up ya movió el cursor).
    expect(row.firstPaymentDate, DateTime(2026, 7, 10));
    expect(row.nextDate, DateTime(2026, 8, 10));
    expect(row.note, 'Arriendo actualizado');
    // La ocurrencia pendiente del 10-jul sigue viva.
    final occurrences =
        await (database.select(database.scheduledPaymentOccurrences)
              ..where((o) => o.scheduledPaymentId.equals(id)))
            .get();
    expect(occurrences, hasLength(1));
    expect(occurrences.single.occurrenceDate, DateTime(2026, 7, 10));
  });
}
