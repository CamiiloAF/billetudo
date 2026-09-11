import 'package:billetudo/features/capture/domain/entities/capture_ingestion.dart';
import 'package:billetudo/features/capture/domain/entities/parsed_capture.dart';
import 'package:billetudo/features/capture/domain/entities/pending_capture.dart';
import 'package:billetudo/features/capture/domain/repositories/capture_learning_repository.dart';
import 'package:billetudo/features/capture/domain/repositories/capture_offer_repository.dart';
import 'package:billetudo/features/capture/domain/repositories/issuer_settings_repository.dart';
import 'package:billetudo/features/capture/domain/repositories/notification_capture_repository.dart';
import 'package:billetudo/features/capture/domain/repositories/pending_capture_repository.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:mocktail/mocktail.dart';

class MockPendingCaptureRepository extends Mock
    implements PendingCaptureRepository {}

class MockCaptureLearningRepository extends Mock
    implements CaptureLearningRepository {}

class MockIssuerSettingsRepository extends Mock
    implements IssuerSettingsRepository {}

class MockNotificationCaptureRepository extends Mock
    implements NotificationCaptureRepository {}

class MockCaptureOfferRepository extends Mock
    implements CaptureOfferRepository {}

/// Registers the fallbacks mocktail needs for `any()` on custom types.
void registerCaptureFallbacks() {
  registerFallbackValue(
    TransactionDraft(
      accountId: 'fallback',
      amountMinor: 1,
      currency: 'COP',
      type: TransactionType.expense,
      date: DateTime(2026),
    ),
  );
  registerFallbackValue(const <CaptureIngestion>[]);
  registerFallbackValue(Duration.zero);
  registerFallbackValue(DateTime(2026));
  registerFallbackValue(
    ParsedCapture(
      sourcePackage: 'fallback',
      postedAt: DateTime(2026),
      amountMinor: 1,
      currency: 'COP',
      entryType: TransactionType.expense,
    ),
  );
}

/// A capture as it looks in the inbox, with every field overridable so each
/// test states only what it is about.
PendingCapture buildPendingCapture({
  String id = 'capture-1',
  String sourcePackage = 'com.nu.production',
  DateTime? postedAt,
  int amountMinor = 4590000,
  String currency = 'COP',
  TransactionType entryType = TransactionType.expense,
  String? merchantRaw = 'EXITO CALLE 80',
  String? accountHint = '1234',
  String? suggestedAccountId,
  String? suggestedCategoryId,
  CaptureStatus status = CaptureStatus.pending,
  String? transactionId,
}) =>
    PendingCapture(
      id: id,
      source: TransactionSource.notification,
      sourcePackage: sourcePackage,
      postedAt: postedAt ?? DateTime(2026, 9, 1, 12),
      amountMinor: amountMinor,
      currency: currency,
      entryType: entryType,
      merchantRaw: merchantRaw,
      accountHint: accountHint,
      suggestedAccountId: suggestedAccountId,
      suggestedCategoryId: suggestedCategoryId,
      status: status,
      transactionId: transactionId,
      createdAt: DateTime(2026, 9, 1, 12),
      updatedAt: DateTime(2026, 9, 1, 12).millisecondsSinceEpoch,
    );
