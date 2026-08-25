import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/domain/repositories/backup_id_collision_resolver.dart';
import 'package:billetudo/features/import_export/domain/usecases/resolve_backup_id_conflicts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupIdCollisionResolver extends Mock
    implements BackupIdCollisionResolver {}

void main() {
  late MockBackupIdCollisionResolver resolver;
  late ResolveBackupIdConflicts useCase;

  setUp(() {
    resolver = MockBackupIdCollisionResolver();
    useCase = ResolveBackupIdConflicts(resolver);
    registerFallbackValue(<String, List<String>>{});
  });

  Map<String, dynamic> row(Map<String, dynamic> fields) => fields;

  test('sin colisión, devuelve las tablas sin ningún cambio (byte a byte)',
      () async {
    when(() => resolver.findCollidingIds(
          userId: any(named: 'userId'),
          idsByTable: any(named: 'idsByTable'),
        )).thenAnswer((_) async => const Right({}));
    final tables = {
      'accounts': [
        row({'id': 'acc-1', 'name': 'Efectivo'}),
      ],
    };

    final result = await useCase(userId: 'user-1', tables: tables);

    expect(result.getRight().toNullable(), tables);
  });

  test('no llama al resolver cuando todas las tablas están vacías', () async {
    final result = await useCase(
      userId: 'user-1',
      tables: {'accounts': <Map<String, dynamic>>[]},
    );

    expect(result.isRight(), isTrue);
    verifyNever(() => resolver.findCollidingIds(
          userId: any(named: 'userId'),
          idsByTable: any(named: 'idsByTable'),
        ));
  });

  test('nunca incluye appSettings en el chequeo de colisión de ids',
      () async {
    Map<String, List<String>>? capturedIdsByTable;
    when(() => resolver.findCollidingIds(
          userId: any(named: 'userId'),
          idsByTable: any(named: 'idsByTable'),
        )).thenAnswer((invocation) async {
      capturedIdsByTable = invocation.namedArguments[#idsByTable]
          as Map<String, List<String>>;
      return const Right({});
    });
    final tables = {
      'appSettings': [
        row({'id': 'app', 'featuredBudgetId': null}),
      ],
      'accounts': [
        row({'id': 'acc-1'}),
      ],
    };

    await useCase(userId: 'user-1', tables: tables);

    expect(capturedIdsByTable, isNotNull);
    expect(capturedIdsByTable!.containsKey('appSettings'), isFalse);
    expect(capturedIdsByTable!['accounts'], ['acc-1']);
  });

  test('remapea el id colisionado a un UUID nuevo, nunca el original',
      () async {
    when(() => resolver.findCollidingIds(
          userId: any(named: 'userId'),
          idsByTable: any(named: 'idsByTable'),
        )).thenAnswer((_) async => const Right({
          'accounts': ['acc-1'],
        }));
    final tables = {
      'accounts': [
        row({'id': 'acc-1', 'name': 'Efectivo'}),
      ],
    };

    final result = await useCase(userId: 'user-1', tables: tables);

    final rewritten = result.getRight().toNullable()!;
    final accountRows = rewritten['accounts'] as List<dynamic>;
    final rewrittenId = (accountRows.single as Map)['id'] as String;
    expect(rewrittenId, isNot('acc-1'));
    expect(rewrittenId, isNotEmpty);
  });

  test(
      'reescribe una FK "dura" (con .references() en Drift) que apunta a un '
      'id remapeado en otra tabla', () async {
    when(() => resolver.findCollidingIds(
          userId: any(named: 'userId'),
          idsByTable: any(named: 'idsByTable'),
        )).thenAnswer((_) async => const Right({
          'accounts': ['acc-1'],
        }));
    final tables = {
      'accounts': [
        row({'id': 'acc-1', 'name': 'Efectivo'}),
      ],
      'transactions': [
        row({'id': 'tx-1', 'accountId': 'acc-1', 'categoryId': null}),
      ],
    };

    final result = await useCase(userId: 'user-1', tables: tables);

    final rewritten = result.getRight().toNullable()!;
    final newAccountId =
        ((rewritten['accounts'] as List<dynamic>).single as Map)['id']
            as String;
    final rewrittenAccountId =
        ((rewritten['transactions'] as List<dynamic>).single as Map)
            ['accountId'] as String;
    expect(rewrittenAccountId, newAccountId);
    expect(rewrittenAccountId, isNot('acc-1'));
  });

  test(
      'reescribe las 3 FK "blandas" (sin .references() en Drift): '
      'goalContributions.transactionId, debts.initialTransactionId, '
      'appSettings.featuredBudgetId', () async {
    when(() => resolver.findCollidingIds(
          userId: any(named: 'userId'),
          idsByTable: any(named: 'idsByTable'),
        )).thenAnswer((_) async => const Right({
          'transactions': ['tx-1'],
          'budgets': ['budget-1'],
        }));
    final tables = {
      'transactions': [
        row({'id': 'tx-1', 'accountId': 'acc-1', 'categoryId': null}),
      ],
      'goalContributions': [
        row({'id': 'gc-1', 'goalId': 'goal-1', 'transactionId': 'tx-1'}),
      ],
      'debts': [
        row({'id': 'debt-1', 'initialTransactionId': 'tx-1'}),
      ],
      'budgets': [
        row({'id': 'budget-1', 'name': 'Mercado'}),
      ],
      'appSettings': [
        row({'id': 'app', 'featuredBudgetId': 'budget-1'}),
      ],
    };

    final result = await useCase(userId: 'user-1', tables: tables);

    final rewritten = result.getRight().toNullable()!;
    final newTxId =
        ((rewritten['transactions'] as List<dynamic>).single as Map)['id']
            as String;
    final newBudgetId =
        ((rewritten['budgets'] as List<dynamic>).single as Map)['id']
            as String;
    expect(newTxId, isNot('tx-1'));
    expect(newBudgetId, isNot('budget-1'));

    final goalContribution =
        (rewritten['goalContributions'] as List<dynamic>).single as Map;
    expect(goalContribution['transactionId'], newTxId);

    final debt = (rewritten['debts'] as List<dynamic>).single as Map;
    expect(debt['initialTransactionId'], newTxId);

    final appSettings =
        (rewritten['appSettings'] as List<dynamic>).single as Map;
    expect(appSettings['featuredBudgetId'], newBudgetId);
    expect(
      appSettings['id'],
      'app',
      reason: 'appSettings is a fixed singleton row (id always "app") — its '
          'own id must never be remapped even if it collided, only FK '
          'columns pointing elsewhere',
    );
  });

  test('no remapea ids que no colisionaron', () async {
    when(() => resolver.findCollidingIds(
          userId: any(named: 'userId'),
          idsByTable: any(named: 'idsByTable'),
        )).thenAnswer((_) async => const Right({
          'accounts': ['acc-1'],
        }));
    final tables = {
      'accounts': [
        row({'id': 'acc-1'}),
        row({'id': 'acc-2'}),
      ],
    };

    final result = await useCase(userId: 'user-1', tables: tables);

    final rewritten = result.getRight().toNullable()!;
    final ids = (rewritten['accounts'] as List<dynamic>)
        .map((r) => (r as Map)['id'] as String)
        .toList();
    expect(ids, contains('acc-2'));
    expect(ids, isNot(contains('acc-1')));
  });

  test('propaga Left(NetworkFailure) sin remapear nada cuando el chequeo '
      'de colisión falla', () async {
    when(() => resolver.findCollidingIds(
          userId: any(named: 'userId'),
          idsByTable: any(named: 'idsByTable'),
        )).thenAnswer(
      (_) async => const Left(NetworkFailure('sin red')),
    );
    final tables = {
      'accounts': [
        row({'id': 'acc-1'}),
      ],
    };

    final result = await useCase(userId: 'user-1', tables: tables);

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
  });
}
