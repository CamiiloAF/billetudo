import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/data/datasources/pending_captures_local_datasource.dart';
import 'package:billetudo/features/capture/data/repositories/pending_capture_repository_impl.dart';
import 'package:billetudo/features/capture/domain/entities/capture_ingestion.dart';
import 'package:billetudo/features/capture/domain/entities/parsed_capture.dart';
import 'package:billetudo/features/capture/domain/entities/pending_capture.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late PendingCaptureRepositoryImpl repository;

  final postedAt = DateTime(2026, 9, 1, 12);

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    repository = PendingCaptureRepositoryImpl(
      PendingCapturesLocalDatasource(database),
      const NoopCrashReporter(),
    );
  });

  tearDown(() async => database.close());

  Future<db.Account> createAccount({
    String name = 'Nu',
    String? cardLast4,
    String? last4,
  }) =>
      database.into(database.accounts).insertReturning(
            db.AccountsCompanion.insert(
              name: name,
              type: db.AccountType.bank,
              currency: 'COP',
              cardLast4: Value(cardLast4),
              last4: Value(last4),
            ),
          );

  Future<db.Category> createCategory() =>
      database.into(database.categories).insertReturning(
            db.CategoriesCompanion.insert(
              name: 'Mercado',
              kind: db.CategoryKind.expense,
            ),
          );

  CaptureIngestion ingestion({
    String sourcePackage = 'com.nu.production',
    int amountMinor = 4590000,
    DateTime? at,
    String? merchantRaw = 'EXITO CALLE 80',
    String? accountHint = '1234',
    String? suggestedAccountId,
  }) =>
      CaptureIngestion(
        parsed: ParsedCapture(
          sourcePackage: sourcePackage,
          postedAt: at ?? postedAt,
          amountMinor: amountMinor,
          currency: 'COP',
          entryType: TransactionType.expense,
          merchantRaw: merchantRaw,
          accountHint: accountHint,
        ),
        suggestedAccountId: suggestedAccountId,
      );

  Future<PendingCapture> ingestOne([CaptureIngestion? one]) async {
    final result = await repository.ingestParsedCaptures([one ?? ingestion()]);
    return result.getOrElse((_) => throw StateError('ingest failed')).single;
  }

  group('ingestParsedCaptures', () {
    test('creates a pending capture and no transaction at all', () async {
      final capture = await ingestOne();

      expect(capture.status, CaptureStatus.pending);
      expect(capture.transactionId, isNull);
      expect(capture.source, TransactionSource.notification);
      expect(await database.select(database.transactions).get(), isEmpty);
    });

    test('gives every capture a UUID and stamps updatedAt', () async {
      final capture = await ingestOne();

      expect(capture.id, hasLength(36));
      expect(capture.updatedAt, greaterThan(0));
    });

    test('keeps the amount a positive integer of cents', () async {
      final capture = await ingestOne(ingestion(amountMinor: 4590000));

      expect(capture.amountMinor, 4590000);
      expect(capture.amountMinor, isPositive);
    });
  });

  group('watchPendingCaptures', () {
    test('lists only pending rows, newest posting first', () async {
      final older = await ingestOne(
        ingestion(at: postedAt.subtract(const Duration(days: 1))),
      );
      final newer = await ingestOne();
      await repository.discardCapture(older.id);

      final captures = await repository.watchPendingCaptures().first;

      expect(
        captures.getOrElse((_) => const []).map((capture) => capture.id),
        [newer.id],
      );
    });

    test('the badge counts exactly what the inbox lists', () async {
      await ingestOne();
      await ingestOne(ingestion(amountMinor: 100000));
      final discarded = await ingestOne(ingestion(amountMinor: 200000));
      await repository.discardCapture(discarded.id);

      final count = await repository.watchPendingCaptureCount().first;

      expect(count.getOrElse((_) => -1), 2);
    });
  });

  group('confirmCapture', () {
    test('creates the transaction with source = notification', () async {
      final account = await createAccount();
      final category = await createCategory();
      final capture = await ingestOne();

      final result = await repository.confirmCapture(
        captureId: capture.id,
        draft: TransactionDraft(
          accountId: account.id,
          categoryId: category.id,
          categoryKind: CategoryKind.expense,
          amountMinor: capture.amountMinor,
          currency: capture.currency,
          type: TransactionType.expense,
          date: capture.postedAt,
          source: TransactionSource.notification,
        ),
      );

      final created = result.getOrElse((_) => throw StateError('failed'));
      expect(created.source, TransactionSource.notification);

      final stored = await repository.getCapture(capture.id);
      final confirmed = stored.getOrElse((_) => throw StateError('missing'));
      expect(confirmed.status, CaptureStatus.confirmed);
      expect(confirmed.transactionId, created.id);
      expect(confirmed.updatedAt, greaterThanOrEqualTo(capture.updatedAt));
    });

    test('refuses to confirm the same capture twice', () async {
      final account = await createAccount();
      final category = await createCategory();
      final capture = await ingestOne();
      final draft = TransactionDraft(
        accountId: account.id,
        categoryId: category.id,
        categoryKind: CategoryKind.expense,
        amountMinor: capture.amountMinor,
        currency: capture.currency,
        type: TransactionType.expense,
        date: capture.postedAt,
      );

      await repository.confirmCapture(captureId: capture.id, draft: draft);
      final second = await repository.confirmCapture(
        captureId: capture.id,
        draft: draft,
      );

      expect(second.getLeft().toNullable(), isA<ValidationFailure>());
      expect(await database.select(database.transactions).get(), hasLength(1));
    });
  });

  group('discard / restore / purge', () {
    test('discarding creates nothing and keeps the row for undo', () async {
      final capture = await ingestOne();

      await repository.discardCapture(capture.id);
      final stored = await repository.getCapture(capture.id);

      expect(
        stored.getOrElse((_) => throw StateError('missing')).status,
        CaptureStatus.discarded,
      );
      expect(await database.select(database.transactions).get(), isEmpty);
    });

    test('records which transaction the user said it duplicated', () async {
      final capture = await ingestOne();

      await repository.discardCapture(
        capture.id,
        duplicateOfTransactionId: null,
      );
      final stored = await repository.getCapture(capture.id);

      expect(
        stored
            .getOrElse((_) => throw StateError('missing'))
            .duplicateOfTransactionId,
        isNull,
      );
    });

    test('restoring puts it back in the inbox and clears the mark', () async {
      final capture = await ingestOne();
      await repository.discardCapture(capture.id);

      await repository.restoreCapture(capture.id);
      final stored = await repository.getCapture(capture.id);

      final restored = stored.getOrElse((_) => throw StateError('missing'));
      expect(restored.status, CaptureStatus.pending);
      expect(restored.duplicateOfTransactionId, isNull);
    });

    test('restoring an unknown capture fails instead of pretending', () async {
      final result = await repository.restoreCapture('nope');

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test('batch discard returns only the ids it touched', () async {
      final old = await ingestOne(
        ingestion(at: postedAt.subtract(const Duration(days: 10))),
      );
      await ingestOne();

      final result = await repository.discardCapturesBefore(
        postedAt.subtract(const Duration(days: 1)),
      );

      expect(result.getOrElse((_) => const []), [old.id]);
      final remaining = await repository.watchPendingCaptureCount().first;
      expect(remaining.getOrElse((_) => -1), 1);
    });

    test('purge deletes the row physically, it does not hide it', () async {
      final capture = await ingestOne();
      await repository.discardCapture(capture.id);

      final removed = await repository.purgeDiscardedCaptures(
        DateTime.now().add(const Duration(minutes: 1)),
      );

      expect(removed.getOrElse((_) => 0), 1);
      final rows = await database.select(database.pendingCaptures).get();
      expect(rows, isEmpty);
    });

    test('purge leaves pending captures alone', () async {
      await ingestOne();

      await repository.purgeDiscardedCaptures(
        DateTime.now().add(const Duration(minutes: 1)),
      );

      final rows = await database.select(database.pendingCaptures).get();
      expect(rows, hasLength(1));
    });
  });

  group('duplicate lookups', () {
    test('finds a transaction of the same amount inside the window', () async {
      final account = await createAccount();
      await database.into(database.transactions).insert(
            db.TransactionsCompanion.insert(
              accountId: account.id,
              amountMinor: 4590000,
              currency: 'COP',
              type: db.EntryType.expense,
              date: postedAt.subtract(const Duration(hours: 30)),
            ),
          );

      final result = await repository.findMatchingTransactions(
        amountMinor: 4590000,
        currency: 'COP',
        around: postedAt,
        window: const Duration(hours: 48),
      );

      expect(result.getOrElse((_) => const []), hasLength(1));
    });

    test('ignores a transaction outside the window or of another amount',
        () async {
      final account = await createAccount();
      await database.into(database.transactions).insert(
            db.TransactionsCompanion.insert(
              accountId: account.id,
              amountMinor: 4590000,
              currency: 'COP',
              type: db.EntryType.expense,
              date: postedAt.subtract(const Duration(days: 5)),
            ),
          );

      final outOfWindow = await repository.findMatchingTransactions(
        amountMinor: 4590000,
        currency: 'COP',
        around: postedAt,
        window: const Duration(hours: 48),
      );
      final otherAmount = await repository.findMatchingTransactions(
        amountMinor: 999,
        currency: 'COP',
        around: postedAt,
        window: const Duration(hours: 48),
      );

      expect(outOfWindow.getOrElse((_) => const []), isEmpty);
      expect(otherAmount.getOrElse((_) => const []), isEmpty);
    });

    test('pairs captures from different issuers within minutes', () async {
      final bank = await ingestOne();
      await ingestOne(
        ingestion(
          sourcePackage: 'com.google.android.apps.walletnfcrel',
          at: postedAt.add(const Duration(minutes: 2)),
          accountHint: null,
        ),
      );

      final result = await repository.findMatchingCaptures(
        excludeId: bank.id,
        amountMinor: 4590000,
        currency: 'COP',
        around: postedAt,
        window: const Duration(minutes: 10),
      );

      final matches = result.getOrElse((_) => const []);
      expect(matches, hasLength(1));
      expect(matches.single.sourcePackage, isNot(bank.sourcePackage));
    });

    test('never returns the capture being reviewed', () async {
      final capture = await ingestOne();

      final result = await repository.findMatchingCaptures(
        excludeId: capture.id,
        amountMinor: capture.amountMinor,
        currency: capture.currency,
        around: postedAt,
        window: const Duration(minutes: 10),
      );

      expect(result.getOrElse((_) => const []), isEmpty);
    });
  });

  group('findAccountIdByLast4', () {
    test('prefers the card last-4 over the account last-4', () async {
      final byAccountNumber =
          await createAccount(name: 'Ahorros', last4: '1234');
      final byCard = await createAccount(name: 'Tarjeta', cardLast4: '1234');

      final result = await repository.findAccountIdByLast4('1234');

      expect(result.getOrElse((_) => null), byCard.id);
      expect(result.getOrElse((_) => null), isNot(byAccountNumber.id));
    });

    test('falls back to the account last-4 when no card matches', () async {
      final account = await createAccount(last4: '9876');

      final result = await repository.findAccountIdByLast4('9876');

      expect(result.getOrElse((_) => null), account.id);
    });

    test('suggests nothing when two cards end the same', () async {
      await createAccount(name: 'Una', cardLast4: '1234');
      await createAccount(name: 'Otra', cardLast4: '1234');

      final result = await repository.findAccountIdByLast4('1234');

      expect(result.getOrElse((_) => 'x'), isNull);
    });

    test('suggests nothing when nothing matches', () async {
      await createAccount(cardLast4: '0000');

      final result = await repository.findAccountIdByLast4('1234');

      expect(result.getOrElse((_) => 'x'), isNull);
    });
  });

  group('deleteAllCaptures', () {
    test('wipes every capture but keeps the confirmed transactions', () async {
      final account = await createAccount();
      final category = await createCategory();
      final capture = await ingestOne();
      await repository.confirmCapture(
        captureId: capture.id,
        draft: TransactionDraft(
          accountId: account.id,
          categoryId: category.id,
          categoryKind: CategoryKind.expense,
          amountMinor: capture.amountMinor,
          currency: capture.currency,
          type: TransactionType.expense,
          date: capture.postedAt,
        ),
      );
      await ingestOne(ingestion(amountMinor: 700000));

      await repository.deleteAllCaptures();

      expect(await database.select(database.pendingCaptures).get(), isEmpty);
      expect(await database.select(database.transactions).get(), hasLength(1));
    });
  });
}
