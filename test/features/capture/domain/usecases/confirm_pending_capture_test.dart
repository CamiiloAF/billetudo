import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/usecases/confirm_pending_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/learn_merchant_category.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

void main() {
  late MockPendingCaptureRepository repository;
  late MockCaptureLearningRepository learning;
  late ConfirmPendingCapture confirm;

  final createdAt = DateTime(2026, 9, 1, 12);

  setUpAll(registerCaptureFallbacks);

  Transaction createdTransaction({
    TransactionSource source = TransactionSource.notification,
  }) =>
      Transaction(
        id: 'tx-1',
        accountId: 'account-1',
        amountMinor: 4590000,
        currency: 'COP',
        type: TransactionType.expense,
        date: createdAt,
        source: source,
        createdAt: createdAt,
        updatedAt: createdAt.millisecondsSinceEpoch,
      );

  setUp(() {
    repository = MockPendingCaptureRepository();
    learning = MockCaptureLearningRepository();
    confirm = ConfirmPendingCapture(
      repository,
      LearnMerchantCategory(learning),
    );

    when(() => repository.getCapture(any()))
        .thenAnswer((_) async => Right(buildPendingCapture()));
    when(
      () => repository.confirmCapture(
        captureId: any(named: 'captureId'),
        draft: any(named: 'draft'),
      ),
    ).thenAnswer((_) async => Right(createdTransaction()));
    when(
      () => learning.learnMerchantCategory(
        merchantKey: any(named: 'merchantKey'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  TransactionDraft draft({
    String? categoryId = 'category-1',
    CategoryKind? categoryKind = CategoryKind.expense,
    int amountMinor = 4590000,
    TransactionSource source = TransactionSource.manual,
  }) =>
      TransactionDraft(
        accountId: 'account-1',
        categoryId: categoryId,
        categoryKind: categoryKind,
        amountMinor: amountMinor,
        currency: 'COP',
        type: TransactionType.expense,
        date: createdAt,
        note: 'EXITO CALLE 80',
        source: source,
      );

  TransactionDraft confirmedDraft() => verify(
        () => repository.confirmCapture(
          captureId: any(named: 'captureId'),
          draft: captureAny(named: 'draft'),
        ),
      ).captured.single as TransactionDraft;

  test('stamps source = notification whatever the caller passed', () async {
    await confirm(captureId: 'capture-1', draft: draft());

    expect(confirmedDraft().source, TransactionSource.notification);
  });

  test('creates, never edits: the draft id is not carried over', () async {
    await confirm(captureId: 'capture-1', draft: draft());

    expect(confirmedDraft().id, isNull);
  });

  test('refuses a draft the transaction form would have rejected', () async {
    final result = await confirm(
      captureId: 'capture-1',
      draft: draft(categoryId: null, categoryKind: null),
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(
      () => repository.confirmCapture(
        captureId: any(named: 'captureId'),
        draft: any(named: 'draft'),
      ),
    );
  });

  test('refuses a non-positive amount', () async {
    final result = await confirm(
      captureId: 'capture-1',
      draft: draft(amountMinor: 0),
    );

    expect(result.isLeft(), isTrue);
  });

  test('learns the merchant to category pairing the user chose', () async {
    await confirm(captureId: 'capture-1', draft: draft());

    verify(
      () => learning.learnMerchantCategory(
        merchantKey: 'EXITO CALLE 80',
        categoryId: 'category-1',
      ),
    ).called(1);
  });

  test('does not learn when the capture had no merchant', () async {
    when(() => repository.getCapture(any())).thenAnswer(
      (_) async => Right(buildPendingCapture(merchantRaw: null)),
    );

    await confirm(captureId: 'capture-1', draft: draft());

    verifyNever(
      () => learning.learnMerchantCategory(
        merchantKey: any(named: 'merchantKey'),
        categoryId: any(named: 'categoryId'),
      ),
    );
  });

  test('still succeeds when learning fails: the movement exists', () async {
    when(
      () => learning.learnMerchantCategory(
        merchantKey: any(named: 'merchantKey'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => const Left(DatabaseFailure('learning failed')));

    final result = await confirm(captureId: 'capture-1', draft: draft());

    expect(result.isRight(), isTrue);
  });

  test('propagates an unknown capture without creating anything', () async {
    when(() => repository.getCapture(any()))
        .thenAnswer((_) async => const Left(NotFoundFailure('gone')));

    final result = await confirm(captureId: 'capture-1', draft: draft());

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    verifyNever(
      () => repository.confirmCapture(
        captureId: any(named: 'captureId'),
        draft: any(named: 'draft'),
      ),
    );
  });
}
