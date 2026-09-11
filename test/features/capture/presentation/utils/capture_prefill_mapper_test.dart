import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/utils/capture_prefill_mapper.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../capture_mocks.dart';

void main() {
  test('carries every field the pre-filled form needs, and the capture id', () {
    final item = CaptureReviewItem(
      capture: buildPendingCapture(
        id: 'capture-9',
        amountMinor: 5847000,
        merchantRaw: 'TIENDA D1 SANTA ROSA',
        suggestedAccountId: 'acc-1',
        suggestedCategoryId: 'cat-1',
        postedAt: DateTime(2026, 9, 1, 8, 32),
      ),
      accountName: 'Cuenta Nu',
    );

    final prefill = capturePrefillFor(item);

    // The capture id is what turns the save into a confirmation instead of a
    // plain creation.
    expect(prefill.captureId, 'capture-9');
    expect(prefill.amountMinor, 5847000);
    expect(prefill.currency, 'COP');
    expect(prefill.type, TransactionType.expense);
    expect(prefill.postedAt, DateTime(2026, 9, 1, 8, 32));
    expect(prefill.accountId, 'acc-1');
    expect(prefill.note, 'TIENDA D1 SANTA ROSA');
    expect(prefill.categoryId, 'cat-1');
  });

  test('a capture with no suggestion leaves the form on its own defaults', () {
    final prefill = capturePrefillFor(
      CaptureReviewItem(capture: buildPendingCapture(merchantRaw: null)),
    );

    expect(prefill.accountId, isNull);
    expect(prefill.categoryId, isNull);
    expect(prefill.note, isNull);
  });
}
