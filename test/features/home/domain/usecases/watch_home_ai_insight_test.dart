import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/home/domain/entities/home_ai_insight.dart';
import 'package:billetudo/features/home/domain/entities/home_insight_event_snapshot.dart';
import 'package:billetudo/features/home/domain/entities/month_spending.dart';
import 'package:billetudo/features/home/domain/repositories/home_insight_event_repository.dart';
import 'package:billetudo/features/home/domain/usecases/watch_home_ai_insight.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../transactions/domain/usecases/transaction_repository_mock.dart';
import '../../home_fixtures.dart';
import '../home_hero_fixtures.dart';

class MockHomeInsightEventRepository extends Mock
    implements HomeInsightEventRepository {}

void main() {
  late MockTransactionRepository repository;
  late MockHomeInsightEventRepository eventRepository;
  late WatchHomeAiInsight useCase;

  final month = DateTime(2026, 7);

  setUpAll(registerTransactionFallbacks);

  setUp(() {
    repository = MockTransactionRepository();
    eventRepository = MockHomeInsightEventRepository();
    useCase = WatchHomeAiInsight(repository, eventRepository);
    when(() => eventRepository.watch()).thenAnswer(
      (_) => Stream.value(const Right(HomeInsightEventSnapshot())),
    );
  });

  MonthSpending spending({int totalMinor = 100000}) => MonthSpending(
        month: month,
        subtotals: [CurrencySpending(currency: 'COP', totalMinor: totalMinor)],
        displayCurrency: 'COP',
      );

  test(
      'sin ningún presupuesto -> fuerza createBudget, sin tocar el '
      'repositorio', () async {
    when(() => repository.watchTransactions(any())).thenAnswer(
      (_) => Stream.value(const Right(<TransactionWithDetails>[])),
    );

    final result = await useCase(
      month: month,
      spending: spending(),
      hasAnyBudget: false,
    ).first;

    final insight = result.getRight().toNullable();
    expect(insight?.type, HomeAiInsightType.createBudget);
    expect(insight?.hasQueue, isFalse);
    verifyNever(() => repository.watchTransactions(any()));
    verifyNever(() => eventRepository.watch());
  });

  test(
      'con presupuesto en riesgo de sobregiro proyectado -> insight '
      'budgetProjectionRisk', () async {
    final budget = buildBudgetWithProgress(
      createdAt: DateTime(2026, 1, 1),
      progress: const BudgetProgress(
        amountMinor: 100000,
        spentMinor: 50000,
        daysLeft: 5,
        scheduledMinor: 60000,
      ),
    );
    when(() => repository.watchTransactions(any())).thenAnswer(
      (_) => Stream.value(const Right(<TransactionWithDetails>[])),
    );

    final result = await useCase(
      month: month,
      spending: spending(),
      hasAnyBudget: true,
      featuredBudget: budget,
    ).first;

    final insight = result.getRight().toNullable();
    expect(insight?.type, HomeAiInsightType.budgetProjectionRisk);
    expect(insight?.overageMinor, budget.progress.scheduledOverageMinor);
    expect(insight?.hasQueue, isFalse);
  });

  test(
      'gasto muy por encima del promedio de los 3 meses anteriores -> '
      'insight spendingVsAverage', () async {
    when(() => repository.watchTransactions(any())).thenAnswer(
      (_) => Stream.value(
        Right([
          buildActivity(
              id: 'm1', amountMinor: 50000, date: DateTime(2026, 4, 10)),
          buildActivity(
              id: 'm2', amountMinor: 50000, date: DateTime(2026, 5, 10)),
          buildActivity(
              id: 'm3', amountMinor: 50000, date: DateTime(2026, 6, 10)),
        ]),
      ),
    );

    final result = await useCase(
      month: month,
      spending: spending(totalMinor: 100000),
      hasAnyBudget: true,
    ).first;

    final insight = result.getRight().toNullable();
    expect(insight?.type, HomeAiInsightType.spendingVsAverage);
    expect(insight?.percentDelta, 100);
    expect(insight?.hasQueue, isFalse);
  });

  test('sin 3 meses completos de historial -> sin insight de promedio',
      () async {
    when(() => repository.watchTransactions(any())).thenAnswer(
      (_) => Stream.value(
        Right([
          buildActivity(
              id: 'm1', amountMinor: 50000, date: DateTime(2026, 6, 10)),
        ]),
      ),
    );

    final result = await useCase(
      month: month,
      spending: spending(totalMinor: 500000),
      hasAnyBudget: true,
    ).first;

    expect(result.getRight().toNullable(), isNull);
  });

  test('desvío chico frente al promedio no vale la pena mostrarse', () async {
    when(() => repository.watchTransactions(any())).thenAnswer(
      (_) => Stream.value(
        Right([
          buildActivity(
              id: 'm1', amountMinor: 100000, date: DateTime(2026, 4, 10)),
          buildActivity(
              id: 'm2', amountMinor: 100000, date: DateTime(2026, 5, 10)),
          buildActivity(
              id: 'm3', amountMinor: 100000, date: DateTime(2026, 6, 10)),
        ]),
      ),
    );

    final result = await useCase(
      month: month,
      spending: spending(totalMinor: 102000),
      hasAnyBudget: true,
    ).first;

    expect(result.getRight().toNullable(), isNull);
  });

  test(
      'con riesgo proyectado Y desvío de promedio, ambos se encolan y el '
      'riesgo sale primero', () async {
    final budget = buildBudgetWithProgress(
      createdAt: DateTime(2026, 1, 1),
      progress: const BudgetProgress(
        amountMinor: 100000,
        spentMinor: 50000,
        daysLeft: 5,
        scheduledMinor: 60000,
      ),
    );
    when(() => repository.watchTransactions(any())).thenAnswer(
      (_) => Stream.value(
        Right([
          buildActivity(
              id: 'm1', amountMinor: 50000, date: DateTime(2026, 4, 10)),
          buildActivity(
              id: 'm2', amountMinor: 50000, date: DateTime(2026, 5, 10)),
          buildActivity(
              id: 'm3', amountMinor: 50000, date: DateTime(2026, 6, 10)),
        ]),
      ),
    );

    final result = await useCase(
      month: month,
      spending: spending(totalMinor: 100000),
      hasAnyBudget: true,
      featuredBudget: budget,
    ).first;

    final insight = result.getRight().toNullable();
    expect(insight?.type, HomeAiInsightType.budgetProjectionRisk);
    expect(insight?.hasQueue, isTrue);
    expect(insight?.queueLength, 2);
  });

  test('propaga un fallo del repositorio de transacciones como Left',
      () async {
    const failure = DatabaseFailure('boom');
    when(() => repository.watchTransactions(any())).thenAnswer(
      (_) => Stream.value(const Left(failure)),
    );

    final result = await useCase(
      month: month,
      spending: spending(),
      hasAnyBudget: true,
    ).first;

    expect(result.getLeft().toNullable(), failure);
  });

  test('propaga un fallo del repositorio de eventos como Left', () async {
    const failure = DatabaseFailure('boom');
    when(() => repository.watchTransactions(any())).thenAnswer(
      (_) => Stream.value(const Right(<TransactionWithDetails>[])),
    );
    when(() => eventRepository.watch()).thenAnswer(
      (_) => Stream.value(const Left(failure)),
    );

    final result = await useCase(
      month: month,
      spending: spending(),
      hasAnyBudget: true,
    ).first;

    expect(result.getLeft().toNullable(), failure);
  });

  group('persistencia por tipo (bugfix: no debe reaparecer siempre)', () {
    final budget = buildBudgetWithProgress(
      createdAt: DateTime(2026, 1, 1),
      progress: const BudgetProgress(
        amountMinor: 100000,
        spentMinor: 50000,
        daysLeft: 5,
        scheduledMinor: 60000,
      ),
    );

    setUp(() {
      when(() => repository.watchTransactions(any())).thenAnswer(
        (_) => Stream.value(const Right(<TransactionWithDetails>[])),
      );
    });

    test(
        'un insight descartado este mes no reaparece, aunque la condición '
        'siga vigente', () async {
      when(() => eventRepository.watch()).thenAnswer(
        (_) => Stream.value(
          Right(
            HomeInsightEventSnapshot(
              dismissedAt: {
                HomeAiInsightType.budgetProjectionRisk: DateTime(2026, 7, 5),
              },
            ),
          ),
        ),
      );

      final result = await useCase(
        month: month,
        spending: spending(),
        hasAnyBudget: true,
        featuredBudget: budget,
      ).first;

      expect(result.getRight().toNullable(), isNull);
    });

    test('un insight descartado el mes pasado sí reaparece este mes',
        () async {
      when(() => eventRepository.watch()).thenAnswer(
        (_) => Stream.value(
          Right(
            HomeInsightEventSnapshot(
              dismissedAt: {
                HomeAiInsightType.budgetProjectionRisk: DateTime(2026, 6, 20),
              },
            ),
          ),
        ),
      );

      final result = await useCase(
        month: month,
        spending: spending(),
        hasAnyBudget: true,
        featuredBudget: budget,
      ).first;

      expect(result.getRight().toNullable()?.type,
          HomeAiInsightType.budgetProjectionRisk);
    });

    test(
        'un insight mostrado hace menos de 24h no reaparece, aunque nunca '
        'se haya descartado', () async {
      await withClock(Clock.fixed(DateTime(2026, 7, 10, 12)), () async {
        when(() => eventRepository.watch()).thenAnswer(
          (_) => Stream.value(
            Right(
              HomeInsightEventSnapshot(
                lastShownAt: {
                  HomeAiInsightType.budgetProjectionRisk:
                      DateTime(2026, 7, 10, 1),
                },
              ),
            ),
          ),
        );

        final result = await useCase(
          month: month,
          spending: spending(),
          hasAnyBudget: true,
          featuredBudget: budget,
        ).first;

        expect(result.getRight().toNullable(), isNull);
      });
    });

    test('un insight mostrado hace más de 24h sí puede reaparecer',
        () async {
      await withClock(Clock.fixed(DateTime(2026, 7, 10, 12)), () async {
        when(() => eventRepository.watch()).thenAnswer(
          (_) => Stream.value(
            Right(
              HomeInsightEventSnapshot(
                lastShownAt: {
                  HomeAiInsightType.budgetProjectionRisk:
                      DateTime(2026, 7, 9, 11),
                },
              ),
            ),
          ),
        );

        final result = await useCase(
          month: month,
          spending: spending(),
          hasAnyBudget: true,
          featuredBudget: budget,
        ).first;

        expect(result.getRight().toNullable()?.type,
            HomeAiInsightType.budgetProjectionRisk);
      });
    });

    test(
        'los dos tipos son independientes: descartar uno no afecta al otro',
        () async {
      when(() => repository.watchTransactions(any())).thenAnswer(
        (_) => Stream.value(
          Right([
            buildActivity(
                id: 'm1', amountMinor: 50000, date: DateTime(2026, 4, 10)),
            buildActivity(
                id: 'm2', amountMinor: 50000, date: DateTime(2026, 5, 10)),
            buildActivity(
                id: 'm3', amountMinor: 50000, date: DateTime(2026, 6, 10)),
          ]),
        ),
      );
      when(() => eventRepository.watch()).thenAnswer(
        (_) => Stream.value(
          Right(
            HomeInsightEventSnapshot(
              dismissedAt: {
                HomeAiInsightType.budgetProjectionRisk: DateTime(2026, 7, 5),
              },
            ),
          ),
        ),
      );

      final result = await useCase(
        month: month,
        spending: spending(totalMinor: 100000),
        hasAnyBudget: true,
        featuredBudget: budget,
      ).first;

      // budgetProjectionRisk was dismissed -> spendingVsAverage takes over,
      // alone (no queue, since the dismissed candidate is filtered out
      // before counting).
      final insight = result.getRight().toNullable();
      expect(insight?.type, HomeAiInsightType.spendingVsAverage);
      expect(insight?.hasQueue, isFalse);
    });
  });
}
