import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_accrual_context.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry_draft.dart';
import 'package:billetudo/features/debts/domain/services/debt_interest_calculator.dart';
import 'package:billetudo/features/debts/domain/usecases/accrue_interest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debt_repository_mock.dart';

typedef _BuildEntry = DebtEntryDraft? Function(DebtAccrualContext);

void main() {
  late MockDebtRepository repository;
  late AccrueInterest usecase;

  setUpAll(() {
    registerDebtFallbacks();
    registerFallbackValue((DebtAccrualContext _) => null);
  });

  setUp(() {
    repository = MockDebtRepository();
    usecase = AccrueInterest(repository, const DebtInterestCalculator());
  });

  Debt autoDebt({int? rateBps = 3650, DateTime? closedAt}) => Debt(
        id: 'd1',
        name: 'Crédito',
        direction: DebtDirection.iOwe,
        principalMinor: 1000000,
        currency: 'COP',
        accrualMode: DebtAccrualMode.auto,
        interestRateBps: rateBps,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: 0,
        closedAt: closedAt,
      );

  DebtEntry anyEntry() => DebtEntry(
        id: 'e1',
        debtId: 'd1',
        kind: DebtEntryKind.interestAccrual,
        amountMinor: 1,
        entryDate: DateTime(2026),
        createdAt: DateTime(2026),
        updatedAt: 0,
      );

  /// Stubs `accrueInterestAtomic` the same way the real repository behaves:
  /// it runs the captured `buildEntry` against [freshContext] (standing in
  /// for what a fresh in-transaction read would produce) and turns a
  /// non-null draft into a persisted entry.
  void stubAtomic(DebtAccrualContext freshContext) {
    when(
      () => repository.accrueInterestAtomic(
        debtId: any(named: 'debtId'),
        buildEntry: any(named: 'buildEntry'),
      ),
    ).thenAnswer((invocation) async {
      final buildEntry =
          invocation.namedArguments[#buildEntry]! as _BuildEntry;
      final draft = buildEntry(freshContext);
      if (draft == null) {
        return const Right(null);
      }
      return Right(anyEntry());
    });
  }

  test('posts a positive interest entry with the rate snapshot', () async {
    final context = DebtAccrualContext(
      debt: autoDebt(),
      rawOutstandingMinor: 1000000,
      lastAccrualDate: DateTime(2026, 1, 1),
    );
    when(() => repository.getAccrualContext('d1'))
        .thenAnswer((_) async => Right(context));
    stubAtomic(context);

    await usecase(debtId: 'd1', upTo: DateTime(2026, 1, 2)); // 1 day

    final captured = verify(
      () => repository.accrueInterestAtomic(
        debtId: 'd1',
        buildEntry: captureAny(named: 'buildEntry'),
      ),
    ).captured.single as _BuildEntry;
    final draft = captured(context)!;
    expect(draft.kind, DebtEntryKind.interestAccrual);
    expect(draft.amountMinor, 1000); // 0.1% of 1,000,000 for one day
    expect(draft.rateBpsSnapshot, 3650);
  });

  test('is a no-op when no days elapsed', () async {
    final context = DebtAccrualContext(
      debt: autoDebt(),
      rawOutstandingMinor: 1000000,
      lastAccrualDate: DateTime(2026, 1, 2),
    );
    when(() => repository.getAccrualContext('d1'))
        .thenAnswer((_) async => Right(context));
    stubAtomic(context);

    final result = await usecase(debtId: 'd1', upTo: DateTime(2026, 1, 2));

    expect(result.getRight().toNullable(), isNull);
  });

  test('rejects a manual-mode debt', () async {
    when(() => repository.getAccrualContext('d1')).thenAnswer(
      (_) async => Right(
        DebtAccrualContext(
          debt: Debt(
            id: 'd1',
            name: 'Crédito',
            direction: DebtDirection.iOwe,
            principalMinor: 1000000,
            currency: 'COP',
            accrualMode: DebtAccrualMode.manual,
            interestRateBps: 3650,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: 0,
          ),
          rawOutstandingMinor: 1000000,
        ),
      ),
    );

    final result = await usecase(debtId: 'd1', upTo: DateTime(2026, 2, 1));

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(
      () => repository.accrueInterestAtomic(
        debtId: any(named: 'debtId'),
        buildEntry: any(named: 'buildEntry'),
      ),
    );
  });

  test('rejects auto mode without a rate', () async {
    when(() => repository.getAccrualContext('d1')).thenAnswer(
      (_) async => Right(
        DebtAccrualContext(
          debt: autoDebt(rateBps: null),
          rawOutstandingMinor: 1000000,
        ),
      ),
    );

    final result = await usecase(debtId: 'd1', upTo: DateTime(2026, 2, 1));

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('rejects accrual on a closed debt', () async {
    when(() => repository.getAccrualContext('d1')).thenAnswer(
      (_) async => Right(
        DebtAccrualContext(
          debt: autoDebt(closedAt: DateTime(2026, 1, 15)),
          rawOutstandingMinor: 1000000,
          lastAccrualDate: DateTime(2026, 1, 1),
        ),
      ),
    );

    final result = await usecase(debtId: 'd1', upTo: DateTime(2026, 1, 20));

    final failure = result.getLeft().toNullable();
    expect(failure, isA<ValidationFailure>());
    expect((failure! as ValidationFailure).field, 'closedAt');
    verifyNever(
      () => repository.accrueInterestAtomic(
        debtId: any(named: 'debtId'),
        buildEntry: any(named: 'buildEntry'),
      ),
    );
  });

  test(
    'a concurrent write that already advanced lastAccrualDate makes the '
    'fresh re-read yield no more interest, and buildEntry posts nothing',
    () async {
      // The initial read (what the use case validates against) still shows
      // interest owed for a full day...
      final staleContext = DebtAccrualContext(
        debt: autoDebt(),
        rawOutstandingMinor: 1000000,
        lastAccrualDate: DateTime(2026, 1, 1),
      );
      when(() => repository.getAccrualContext('d1'))
          .thenAnswer((_) async => Right(staleContext));
      // ...but the transaction's own fresh read (as another concurrent
      // caller would have left it after committing first) shows the accrual
      // already caught up to `upTo`.
      final freshContext = DebtAccrualContext(
        debt: autoDebt(),
        rawOutstandingMinor: 1000000,
        lastAccrualDate: DateTime(2026, 1, 2),
      );
      stubAtomic(freshContext);

      final result = await usecase(debtId: 'd1', upTo: DateTime(2026, 1, 2));

      expect(result.getRight().toNullable(), isNull);
    },
  );
}
