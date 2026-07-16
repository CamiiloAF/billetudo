import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/security/secure_storage_service.dart';
import 'package:billetudo/features/accounts/data/datasources/account_number_local_datasource.dart';
import 'package:billetudo/features/accounts/data/datasources/accounts_local_datasource.dart';
import 'package:billetudo/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart'
    as domain;
import 'package:billetudo/features/accounts/domain/entities/account_draft.dart';
import 'package:billetudo/features/accounts/domain/entities/account_number_edit.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
// `Value` only: drift also exports isNull/isNotNull, which collide with the
// matchers of the same name.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late AppDatabase db;
  late MockSecureStorageService storage;
  late AccountRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    storage = MockSecureStorageService();
    when(() => storage.write(any(), any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => storage.read(any())).thenAnswer((_) async => const Right(null));
    when(() => storage.delete(any()))
        .thenAnswer((_) async => const Right(unit));
    repository = AccountRepositoryImpl(
      AccountsLocalDatasource(db),
      AccountNumberLocalDatasource(storage),
    );
  });

  tearDown(() async => db.close());

  Future<domain.Account> createAccount(AccountDraft draft) async {
    final result = await repository.createAccount(draft);
    return result.getRight().toNullable()!;
  }

  Future<Account> rowOf(String id) =>
      (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingle();

  Future<void> insertTransaction({
    required String accountId,
    required int amountMinor,
    required EntryType type,
    String? transferAccountId,
    DateTime? deletedAt,
    String? debtId,
  }) =>
      db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              amountMinor: amountMinor,
              currency: 'COP',
              type: type,
              date: DateTime(2026, 7, 10),
              transferAccountId: Value(transferAccountId),
              deletedAt: Value(deletedAt),
              debtId: Value(debtId),
            ),
          );

  const bankDraft = AccountDraft(
    name: 'Bancolombia',
    type: domain.AccountType.bank,
    currency: 'COP',
    initialBalanceMinor: 100000,
  );

  group('createAccount', () {
    test('persiste la cuenta con id UUID y saldo inicial en centavos',
        () async {
      final account = await createAccount(bankDraft);

      final row = await rowOf(account.id);
      expect(row.id, hasLength(36)); // UUID v4 textual, nunca autoincrement
      expect(row.name, 'Bancolombia');
      expect(row.initialBalanceMinor, 100000);
      expect(row.type, AccountType.bank);
      expect(row.archived, isFalse);
      expect(row.tombstonedAt, isNull);
      expect(row.deletedAt, isNull);
    });

    test(
        'HU-03: el número completo NO se persiste en Drift; va al almacén '
        'seguro', () async {
      final account = await createAccount(
        AccountDraft(
          name: bankDraft.name,
          type: bankDraft.type,
          currency: bankDraft.currency,
          numberEdit: const SetAccountNumber('1234 5678 9012 4321'),
        ).validated().getRight().toNullable()!,
      );

      final row = await rowOf(account.id);
      // El número completo vive solo en Keychain/Keystore, nunca en Drift
      // (la columna que lo hubiera guardado, `account_number_enc`, ya no
      // existe — ver schema v5). last4 sí se persiste: es el único
      // fragmento sincronizable.
      expect(row.last4, '4321');

      verify(
        () => storage.write(
          AccountNumberLocalDatasource.keyFor(account.id),
          '1234 5678 9012 4321',
        ),
      ).called(1);
    });

    test('la clave del almacén seguro se deriva del id de la cuenta', () async {
      final account = await createAccount(
        const AccountDraft(
          name: 'Nu',
          type: domain.AccountType.savings,
          currency: 'COP',
          numberEdit: SetAccountNumber('12344321'),
        ),
      );

      final key = verify(() => storage.write(captureAny(), any()))
          .captured
          .single as String;
      expect(key, contains(account.id));
    });

    test('sin número completo no se toca el almacén seguro', () async {
      await createAccount(bankDraft);

      // Un id recién generado no tiene entrada que borrar, así que ni siquiera
      // se intenta: un Keystore bloqueado no puede hundir la creación de una
      // cuenta que nunca quiso guardar un número.
      verifyNever(() => storage.write(any(), any()));
      verifyNever(() => storage.delete(any()));
    });

    test('si el almacén seguro falla, la creación falla', () async {
      when(() => storage.write(any(), any())).thenAnswer(
        (_) async => const Left(SecureStorageFailure('keychain bloqueado')),
      );

      final result = await repository.createAccount(
        const AccountDraft(
          name: 'Nu',
          type: domain.AccountType.savings,
          currency: 'COP',
          numberEdit: SetAccountNumber('12344321'),
        ),
      );

      expect(result.getLeft().toNullable(), isA<SecureStorageFailure>());
    });

    // Regresión: la fila se insertaba antes de escribir el número, y un Left
    // del almacén seguro volvía sin deshacerla. El formulario mostraba el
    // fallo y seguía sin id, así que el segundo Guardar creaba una cuenta
    // nueva en vez de actualizar la primera.
    test('si el almacén seguro falla, la creación no deja fila huérfana',
        () async {
      when(() => storage.write(any(), any())).thenAnswer(
        (_) async => const Left(SecureStorageFailure('keychain bloqueado')),
      );

      final result = await repository.createAccount(
        const AccountDraft(
          name: 'Nu',
          type: domain.AccountType.savings,
          currency: 'COP',
          numberEdit: SetAccountNumber('12344321'),
        ),
      );

      expect(result.getLeft().toNullable(), isA<SecureStorageFailure>());
      // Left significa que no se creó nada: ni la fila, ni el listado, ni el
      // sortOrder consumido.
      expect(await db.select(db.accounts).get(), isEmpty);
    });

    test('reintentar tras un fallo del almacén seguro no duplica la cuenta',
        () async {
      const draft = AccountDraft(
        name: 'Nu',
        type: domain.AccountType.savings,
        currency: 'COP',
        numberEdit: SetAccountNumber('12344321'),
      );
      when(() => storage.write(any(), any())).thenAnswer(
        (_) async => const Left(SecureStorageFailure('keychain bloqueado')),
      );
      await repository.createAccount(draft);

      // El usuario vuelve a darle Guardar; esta vez el almacén responde.
      when(() => storage.write(any(), any()))
          .thenAnswer((_) async => const Right(unit));
      final retry = await repository.createAccount(draft);

      expect(retry.isRight(), isTrue);
      final rows = await db.select(db.accounts).get();
      expect(rows, hasLength(1));
      expect(rows.single.name, 'Nu');
      // Y el sortOrder sigue siendo contiguo desde 0: la fila descartada no
      // dejó hueco.
      expect(rows.single.sortOrder, 0);
    });

    test('asigna sortOrder contiguo al final de la lista', () async {
      final first = await createAccount(bankDraft);
      final second = await createAccount(bankDraft);
      final third = await createAccount(bankDraft);

      expect((await rowOf(first.id)).sortOrder, 0);
      expect((await rowOf(second.id)).sortOrder, 1);
      expect((await rowOf(third.id)).sortOrder, 2);
    });

    test('una tarjeta persiste cupo y días como enteros', () async {
      final card = await createAccount(
        const AccountDraft(
          name: 'Visa',
          type: domain.AccountType.card,
          currency: 'COP',
          creditLimitMinor: 500000,
          statementDay: 15,
          paymentDueDay: 5,
        ),
      );

      final row = await rowOf(card.id);
      expect(row.creditLimitMinor, 500000);
      expect(row.statementDay, 15);
      expect(row.paymentDueDay, 5);
    });
  });

  group('updateAccount (HU-06)', () {
    test('sube updatedAt por encima del valor anterior', () async {
      final account = await createAccount(bankDraft);
      // `updatedAt` is epoch millis: back-date it so the comparison does not
      // depend on the test running in under a millisecond.
      final backdated = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      await (db.update(db.accounts)..where((a) => a.id.equals(account.id)))
          .write(AccountsCompanion(updatedAt: Value(backdated)));
      final before = (await rowOf(account.id)).updatedAt;

      await repository.updateAccount(
        AccountDraft(
          id: account.id,
          name: 'Bancolombia Ahorros',
          type: domain.AccountType.bank,
          currency: 'COP',
        ),
      );

      final after = await rowOf(account.id);
      expect(after.name, 'Bancolombia Ahorros');
      expect(after.updatedAt > before, isTrue);
    });

    test('no toca createdAt', () async {
      final account = await createAccount(bankDraft);
      final createdAt = (await rowOf(account.id)).createdAt;

      await repository.updateAccount(
        AccountDraft(
          id: account.id,
          name: 'Otro nombre',
          type: domain.AccountType.bank,
          currency: 'COP',
        ),
      );

      expect((await rowOf(account.id)).createdAt, createdAt);
    });

    test('al salir de tarjeta limpia los campos de tarjeta en la fila',
        () async {
      final card = await createAccount(
        const AccountDraft(
          name: 'Visa',
          type: domain.AccountType.card,
          currency: 'COP',
          creditLimitMinor: 500000,
          statementDay: 15,
          paymentDueDay: 5,
        ),
      );

      await repository.updateAccount(
        AccountDraft(
          id: card.id,
          name: 'Ya no es tarjeta',
          type: domain.AccountType.bank,
          currency: 'COP',
        ),
      );

      final row = await rowOf(card.id);
      expect(row.creditLimitMinor, isNull);
      expect(row.statementDay, isNull);
      expect(row.paymentDueDay, isNull);
      expect(row.cardBalancePrimary, isNull);
    });

    test('al cambiar a un tipo sin número, borra el número seguro', () async {
      final account = await createAccount(
        const AccountDraft(
          name: 'Nu',
          type: domain.AccountType.savings,
          currency: 'COP',
          numberEdit: SetAccountNumber('12344321'),
        ),
      );

      await repository.updateAccount(
        AccountDraft(
          id: account.id,
          name: 'Efectivo',
          type: domain.AccountType.cash,
          currency: 'COP',
        ),
      );

      verify(
        () => storage.delete(AccountNumberLocalDatasource.keyFor(account.id)),
      ).called(1);
    });

    // Regresión (HU-03): el número solo vive en este dispositivo y no tiene
    // copia en la nube. Un draft que no lo conoce —porque la lectura del
    // Keystore falló— no puede ser la razón de que desaparezca.
    test('un draft que no conoce el número no lo toca en el almacén seguro',
        () async {
      final account = await createAccount(
        const AccountDraft(
          name: 'Nu',
          type: domain.AccountType.savings,
          currency: 'COP',
          numberEdit: SetAccountNumber('12344321'),
        ),
      );
      clearInteractions(storage);

      final result = await repository.updateAccount(
        AccountDraft(
          id: account.id,
          name: 'Nu renombrada',
          type: domain.AccountType.savings,
          currency: 'COP',
          last4: '4321',
          // Lo que emite el formulario cuando no pudo leer el número guardado.
          // Explícito aunque sea el default: es justo lo que este test afirma.
          // ignore: avoid_redundant_argument_values
          numberEdit: const KeepAccountNumber(),
        ),
      );

      expect(result.isRight(), isTrue);
      verifyNever(() => storage.delete(any()));
      verifyNever(() => storage.write(any(), any()));
    });

    test('vaciar el número a propósito sí lo borra del almacén seguro',
        () async {
      final account = await createAccount(
        const AccountDraft(
          name: 'Nu',
          type: domain.AccountType.savings,
          currency: 'COP',
          numberEdit: SetAccountNumber('12344321'),
        ),
      );

      await repository.updateAccount(
        AccountDraft(
          id: account.id,
          name: 'Nu',
          type: domain.AccountType.savings,
          currency: 'COP',
          numberEdit: const ClearAccountNumber(),
        ),
      );

      verify(
        () => storage.delete(AccountNumberLocalDatasource.keyFor(account.id)),
      ).called(1);
    });

    test('actualizar una cuenta inexistente es NotFound', () async {
      final result = await repository.updateAccount(
        const AccountDraft(
          id: 'no-existe',
          name: 'X',
          type: domain.AccountType.bank,
          currency: 'COP',
        ),
      );

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('saldo derivado vía SQL real (HU-04)', () {
    test('combina saldo inicial, ingresos, gastos y transferencias', () async {
      final account = await createAccount(bankDraft); // 100000
      final other = await createAccount(bankDraft);

      await insertTransaction(
        accountId: account.id,
        amountMinor: 50000,
        type: EntryType.income,
      );
      await insertTransaction(
        accountId: account.id,
        amountMinor: 20000,
        type: EntryType.expense,
      );
      // Sale de `account` hacia `other`.
      await insertTransaction(
        accountId: account.id,
        amountMinor: 10000,
        type: EntryType.transfer,
        transferAccountId: other.id,
      );
      // Entra a `account` desde `other`.
      await insertTransaction(
        accountId: other.id,
        amountMinor: 30000,
        type: EntryType.transfer,
        transferAccountId: account.id,
      );
      // Eliminada: no debe contar.
      await insertTransaction(
        accountId: account.id,
        amountMinor: 999999,
        type: EntryType.expense,
        deletedAt: DateTime(2026, 7, 12),
      );

      final accounts = await repository.watchActiveAccounts().first;
      final balance = accounts
          .getRight()
          .toNullable()!
          .firstWhere((a) => a.account.id == account.id)
          .balance;

      // 100000 + 50000 - 20000 - 10000 + 30000
      expect(balance.balanceMinor, 150000);
    });

    test('una cuenta sin transacciones aparece con su saldo inicial', () async {
      await createAccount(bankDraft);

      final accounts = await repository.watchActiveAccounts().first;

      final list = accounts.getRight().toNullable()!;
      expect(list, hasLength(1));
      expect(list.single.balance.balanceMinor, 100000);
    });

    test('el detalle de una tarjeta expone cupo disponible', () async {
      final card = await createAccount(
        const AccountDraft(
          name: 'Visa',
          type: domain.AccountType.card,
          currency: 'COP',
          creditLimitMinor: 500000,
          statementDay: 15,
          paymentDueDay: 5,
        ),
      );
      await insertTransaction(
        accountId: card.id,
        amountMinor: 120000,
        type: EntryType.expense,
      );

      final result = await repository.watchAccount(card.id).first;

      final balance = result.getRight().toNullable()!.balance;
      expect(balance.balanceMinor, -120000);
      expect(balance.availableCreditMinor, 380000);
    });

    test('el detalle de una cuenta inexistente es NotFound', () async {
      final result = await repository.watchAccount('no-existe').first;

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('listados (HU-07)', () {
    test('el listado activo excluye archivadas y borradas', () async {
      final active = await createAccount(bankDraft);
      final archived = await createAccount(bankDraft);
      final deleted = await createAccount(bankDraft);
      await repository.setArchived(archived.id, archived: true);
      await repository.softDeleteAccount(deleted.id);

      final result = await repository.watchActiveAccounts().first;

      final ids = result.getRight().toNullable()!.map((a) => a.account.id);
      expect(ids, [active.id]);
    });

    test('el listado de archivadas solo trae archivadas no borradas', () async {
      await createAccount(bankDraft);
      final archived = await createAccount(bankDraft);
      final archivedThenDeleted = await createAccount(bankDraft);
      await repository.setArchived(archived.id, archived: true);
      await repository.setArchived(archivedThenDeleted.id, archived: true);
      await repository.softDeleteAccount(archivedThenDeleted.id);

      final result = await repository.watchArchivedAccounts().first;

      final ids = result.getRight().toNullable()!.map((a) => a.account.id);
      expect(ids, [archived.id]);
    });

    test('desarchivar la devuelve al listado activo', () async {
      final account = await createAccount(bankDraft);
      await repository.setArchived(account.id, archived: true);
      await repository.setArchived(account.id, archived: false);

      final active = await repository.watchActiveAccounts().first;

      expect(active.getRight().toNullable(), hasLength(1));
    });
  });

  group('softDeleteAccount (HU-08)', () {
    test('el borrado es lógico: la fila sobrevive y no rompe el FK', () async {
      final account = await createAccount(bankDraft);
      await insertTransaction(
        accountId: account.id,
        amountMinor: 1000,
        type: EntryType.expense,
      );

      final result = await repository.softDeleteAccount(account.id);

      expect(result.isRight(), isTrue);
      final row = await rowOf(account.id);
      // Lápida de integridad referencial, no papelera: el borrado de cuentas es
      // irreversible y `deletedAt` queda libre para su único significado.
      expect(row.tombstonedAt, isNotNull);
      expect(row.deletedAt, isNull);
      // La transacción sigue apuntando a una fila que existe.
      final transactions = await db.select(db.transactions).get();
      expect(transactions.single.accountId, account.id);
    });

    test('borra el número del almacén seguro', () async {
      final account = await createAccount(
        const AccountDraft(
          name: 'Nu',
          type: domain.AccountType.savings,
          currency: 'COP',
          numberEdit: SetAccountNumber('12344321'),
        ),
      );

      await repository.softDeleteAccount(account.id);

      verify(
        () => storage.delete(AccountNumberLocalDatasource.keyFor(account.id)),
      ).called(1);
    });

    test('la cuenta borrada desaparece de todos los listados', () async {
      final account = await createAccount(bankDraft);
      await repository.softDeleteAccount(account.id);

      final active = await repository.watchActiveAccounts().first;
      final archived = await repository.watchArchivedAccounts().first;
      final detail = await repository.watchAccount(account.id).first;
      final byId = await repository.getAccount(account.id);

      expect(active.getRight().toNullable(), isEmpty);
      expect(archived.getRight().toNullable(), isEmpty);
      expect(detail.getLeft().toNullable(), isA<NotFoundFailure>());
      expect(byId.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  // Defensa en profundidad: hoy la UI no ofrece caminos a una cuenta borrada,
  // pero una carrera (detalle abierto mientras se borra en otro flujo) no debe
  // poder resucitarla ni mutarla.
  group('escrituras sobre una cuenta ya borrada', () {
    late domain.Account deleted;
    late DateTime tombstonedAtOriginal;

    setUp(() async {
      deleted = await createAccount(bankDraft);
      await repository.softDeleteAccount(deleted.id);
      tombstonedAtOriginal = (await rowOf(deleted.id)).tombstonedAt!;
    });

    test('updateAccount no la muta y reporta NotFoundFailure', () async {
      final result = await repository.updateAccount(
        AccountDraft(
          id: deleted.id,
          name: 'Renombrada',
          type: domain.AccountType.bank,
          currency: 'COP',
        ),
      );

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
      expect((await rowOf(deleted.id)).name, 'Bancolombia');
    });

    test('setArchived no la des-archiva y reporta NotFoundFailure', () async {
      final result = await repository.setArchived(deleted.id, archived: false);

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
      expect((await rowOf(deleted.id)).tombstonedAt, tombstonedAtOriginal);
    });

    test('setCardBalancePrimary no la toca y reporta NotFoundFailure',
        () async {
      final result = await repository.setCardBalancePrimary(
        deleted.id,
        domain.CardBalanceView.available,
      );

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
      expect((await rowOf(deleted.id)).cardBalancePrimary, isNull);
    });

    test('un segundo softDeleteAccount no pisa el tombstonedAt original',
        () async {
      final result = await repository.softDeleteAccount(deleted.id);

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
      expect((await rowOf(deleted.id)).tombstonedAt, tombstonedAtOriginal);
    });

    test('reorderAccounts ignora los ids de cuentas borradas', () async {
      final active = await createAccount(bankDraft);

      await repository.reorderAccounts([deleted.id, active.id]);

      // La activa toma su lugar; la borrada conserva su sortOrder y su lápida.
      expect((await rowOf(active.id)).sortOrder, 1);
      expect((await rowOf(deleted.id)).sortOrder, 0);
      expect((await rowOf(deleted.id)).tombstonedAt, tombstonedAtOriginal);
    });
  });

  group('getDeletionImpact (HU-08)', () {
    test('cuenta transacciones de ambos lados de una transferencia', () async {
      final account = await createAccount(bankDraft);
      final other = await createAccount(bankDraft);
      await insertTransaction(
        accountId: account.id,
        amountMinor: 1000,
        type: EntryType.expense,
      );
      await insertTransaction(
        accountId: other.id,
        amountMinor: 1000,
        type: EntryType.transfer,
        transferAccountId: account.id,
      );
      await insertTransaction(
        accountId: account.id,
        amountMinor: 1000,
        type: EntryType.expense,
        deletedAt: DateTime(2026, 7, 12),
      );

      final result = await repository.getDeletionImpact(account.id);

      expect(result.getRight().toNullable()!.transactionCount, 2);
    });

    test('cuenta metas asociadas y deudas distintas', () async {
      final account = await createAccount(bankDraft);
      await db.into(db.goals).insert(
            GoalsCompanion.insert(
              name: 'Viaje',
              targetMinor: 100,
              currency: 'COP',
              accountId: Value(account.id),
            ),
          );
      final debtId = await db.into(db.debts).insertReturning(
            DebtsCompanion.insert(
              name: 'Préstamo',
              direction: DebtDirection.iOwe,
              principalMinor: 100,
              currency: 'COP',
            ),
          );
      // Dos transacciones de la MISMA deuda: es una sola deuda impactada.
      await insertTransaction(
        accountId: account.id,
        amountMinor: 1000,
        type: EntryType.expense,
        debtId: debtId.id,
      );
      await insertTransaction(
        accountId: account.id,
        amountMinor: 2000,
        type: EntryType.expense,
        debtId: debtId.id,
      );

      final result = await repository.getDeletionImpact(account.id);

      final impact = result.getRight().toNullable()!;
      expect(impact.goalCount, 1);
      expect(impact.debtCount, 1);
      expect(impact.hasImpact, isTrue);
    });

    test('la única cuenta activa se marca como última', () async {
      final account = await createAccount(bankDraft);

      final result = await repository.getDeletionImpact(account.id);

      expect(result.getRight().toNullable()!.isLastAccount, isTrue);
    });

    test('con dos cuentas activas ninguna es la última', () async {
      final account = await createAccount(bankDraft);
      await createAccount(bankDraft);

      final result = await repository.getDeletionImpact(account.id);

      expect(result.getRight().toNullable()!.isLastAccount, isFalse);
    });

    test('una cuenta archivada no cuenta como cuenta activa restante',
        () async {
      final account = await createAccount(bankDraft);
      final archived = await createAccount(bankDraft);
      await repository.setArchived(archived.id, archived: true);

      final result = await repository.getDeletionImpact(account.id);

      expect(result.getRight().toNullable()!.isLastAccount, isTrue);
    });
  });

  group('reorderAccounts (HU-09)', () {
    test('persiste sortOrder contiguo 0..n-1 en el orden dado', () async {
      final a = await createAccount(bankDraft);
      final b = await createAccount(bankDraft);
      final c = await createAccount(bankDraft);

      // Mover el ítem 0 a la posición 2: [a,b,c] -> [b,c,a].
      await repository.reorderAccounts([b.id, c.id, a.id]);

      expect((await rowOf(b.id)).sortOrder, 0);
      expect((await rowOf(c.id)).sortOrder, 1);
      expect((await rowOf(a.id)).sortOrder, 2);
    });

    test('el listado se emite ordenado por sortOrder tras releer la BD',
        () async {
      final a = await createAccount(bankDraft);
      final b = await createAccount(bankDraft);
      final c = await createAccount(bankDraft);

      await repository.reorderAccounts([b.id, c.id, a.id]);
      final result = await repository.watchActiveAccounts().first;

      final ids = result.getRight().toNullable()!.map((e) => e.account.id);
      expect(ids, [b.id, c.id, a.id]);
    });

    test('reordenar sube updatedAt de las cuentas movidas', () async {
      final a = await createAccount(bankDraft);
      final backdated = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      await (db.update(db.accounts)..where((row) => row.id.equals(a.id)))
          .write(AccountsCompanion(updatedAt: Value(backdated)));

      await repository.reorderAccounts([a.id]);

      expect((await rowOf(a.id)).updatedAt > backdated, isTrue);
    });
  });

  group('setCardBalancePrimary (HU-04)', () {
    test('persiste la preferencia sin tocar el saldo', () async {
      final card = await createAccount(
        const AccountDraft(
          name: 'Visa',
          type: domain.AccountType.card,
          currency: 'COP',
          initialBalanceMinor: -50000,
          creditLimitMinor: 500000,
          statementDay: 15,
          paymentDueDay: 5,
        ),
      );

      await repository.setCardBalancePrimary(
        card.id,
        domain.CardBalanceView.available,
      );

      final row = await rowOf(card.id);
      expect(row.cardBalancePrimary, CardBalanceView.available);
      expect(row.initialBalanceMinor, -50000);
    });
  });

  group('readAccountNumber (HU-03)', () {
    test('lee del almacén seguro con la clave de la cuenta', () async {
      when(() => storage.read(any()))
          .thenAnswer((_) async => const Right('12344321'));

      final result = await repository.readAccountNumber('acc-1');

      expect(result.getRight().toNullable(), '12344321');
      verify(() => storage.read(AccountNumberLocalDatasource.keyFor('acc-1')))
          .called(1);
    });
  });

  group('hasTransactions', () {
    test('es falso sin transacciones y cierto con una', () async {
      final account = await createAccount(bankDraft);

      expect(
        (await repository.hasTransactions(account.id)).getRight().toNullable(),
        isFalse,
      );

      await insertTransaction(
        accountId: account.id,
        amountMinor: 1000,
        type: EntryType.expense,
      );

      expect(
        (await repository.hasTransactions(account.id)).getRight().toNullable(),
        isTrue,
      );
    });

    test('una transacción eliminada no cuenta', () async {
      final account = await createAccount(bankDraft);
      await insertTransaction(
        accountId: account.id,
        amountMinor: 1000,
        type: EntryType.expense,
        deletedAt: DateTime(2026, 7, 12),
      );

      expect(
        (await repository.hasTransactions(account.id)).getRight().toNullable(),
        isFalse,
      );
    });
  });

  test('el stream reacciona a una transacción nueva', () async {
    final account = await createAccount(bankDraft);
    final emissions = <List<AccountWithBalance>>[];
    final subscription = repository.watchActiveAccounts().listen(
          (result) => emissions.add(result.getRight().toNullable()!),
        );
    await pumpEventQueue();

    await insertTransaction(
      accountId: account.id,
      amountMinor: 25000,
      type: EntryType.income,
    );
    await pumpEventQueue();
    await subscription.cancel();

    expect(emissions.first.single.balance.balanceMinor, 100000);
    expect(emissions.last.single.balance.balanceMinor, 125000);
  });
}
