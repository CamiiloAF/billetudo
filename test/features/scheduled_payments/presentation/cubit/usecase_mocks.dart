import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/confirm_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/create_scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/create_tag.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/delete_scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/generate_due_scheduled_payments.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_finished_scheduled_payments.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_pending_occurrences.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payment_detail.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payment_history.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payments.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_tags.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/set_scheduled_payment_tags.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/skip_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/snooze_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/undo_skip_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/undo_snooze_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/update_scheduled_payment.dart';
import 'package:mocktail/mocktail.dart';

/// The cubits only ever talk to use cases, so these are the only seams the
/// presentation tests need. Mirrors
/// `test/features/transactions/presentation/usecase_mocks.dart`.
class MockGetScheduledPayments extends Mock implements GetScheduledPayments {}

class MockGenerateDueScheduledPayments extends Mock
    implements GenerateDueScheduledPayments {}

class MockGetPendingOccurrences extends Mock implements GetPendingOccurrences {}

class MockGetFinishedScheduledPayments extends Mock
    implements GetFinishedScheduledPayments {}

class MockUndoSkipScheduledOccurrence extends Mock
    implements UndoSkipScheduledOccurrence {}

class MockUndoSnoozeScheduledOccurrence extends Mock
    implements UndoSnoozeScheduledOccurrence {}

class MockConfirmScheduledOccurrence extends Mock
    implements ConfirmScheduledOccurrence {}

class MockSkipScheduledOccurrence extends Mock
    implements SkipScheduledOccurrence {}

class MockSnoozeScheduledOccurrence extends Mock
    implements SnoozeScheduledOccurrence {}

class MockCreateScheduledPayment extends Mock
    implements CreateScheduledPayment {}

class MockUpdateScheduledPayment extends Mock
    implements UpdateScheduledPayment {}

class MockGetScheduledPaymentDetail extends Mock
    implements GetScheduledPaymentDetail {}

class MockGetScheduledPaymentHistory extends Mock
    implements GetScheduledPaymentHistory {}

class MockDeleteScheduledPayment extends Mock
    implements DeleteScheduledPayment {}

class MockSetScheduledPaymentTags extends Mock
    implements SetScheduledPaymentTags {}

class MockGetTags extends Mock implements GetTags {}

class MockCreateTag extends Mock implements CreateTag {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

/// Fallbacks mocktail needs for `any()` on the feature's own types.
void registerScheduledPaymentPresentationFallbacks() {
  registerFallbackValue(
    ScheduledPaymentDraft(
      accountId: 'fallback',
      amountMinor: 1,
      currency: 'COP',
      type: ScheduledPaymentType.expense,
      frequency: ScheduledPaymentFrequency.once,
      nextDate: DateTime(2026),
    ),
  );
  registerFallbackValue(DateTime(2026));
  // For `any(named: 'wasCreated')` on `UndoSnoozeScheduledOccurrence`.
  registerFallbackValue(false);
}
