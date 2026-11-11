import 'package:billetudo/features/capture/domain/entities/capture_background_health.dart';
import 'package:billetudo/features/capture/domain/entities/capture_diagnostics.dart';
import 'package:billetudo/features/capture/domain/entities/capture_ingestion.dart';
import 'package:billetudo/features/capture/domain/entities/parsed_capture.dart';
import 'package:billetudo/features/capture/domain/entities/pending_capture.dart';
import 'package:billetudo/features/capture/domain/repositories/capture_background_preferences_repository.dart';
import 'package:billetudo/features/capture/domain/repositories/capture_learning_repository.dart';
import 'package:billetudo/features/capture/domain/repositories/capture_offer_repository.dart';
import 'package:billetudo/features/capture/domain/repositories/issuer_settings_repository.dart';
import 'package:billetudo/features/capture/domain/repositories/notification_capture_repository.dart';
import 'package:billetudo/features/capture/domain/repositories/pending_capture_repository.dart';
import 'package:billetudo/features/capture/domain/usecases/drain_and_ingest_captures.dart';
import 'package:billetudo/features/capture/domain/usecases/get_capture_background_health.dart';
import 'package:billetudo/features/capture/domain/usecases/get_issuer_apps.dart';
import 'package:billetudo/features/capture/domain/usecases/is_notification_access_granted.dart';
import 'package:billetudo/features/capture/domain/usecases/is_notification_capture_supported.dart';
import 'package:billetudo/features/capture/domain/usecases/mark_capture_configured.dart';
import 'package:billetudo/features/capture/domain/usecases/open_capture_autostart_settings.dart';
import 'package:billetudo/features/capture/domain/usecases/request_battery_optimization_exemption.dart';
import 'package:billetudo/features/capture/domain/usecases/snooze_capture_background_alert.dart';
import 'package:billetudo/features/capture/domain/usecases/watch_incoming_captures.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_state.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:bloc_test/bloc_test.dart';
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

class MockCaptureBackgroundPreferencesRepository extends Mock
    implements CaptureBackgroundPreferencesRepository {}

// HU-09 use cases. The cubit is tested against the use cases, never against
// the repositories behind them.
class MockGetCaptureBackgroundHealth extends Mock
    implements GetCaptureBackgroundHealth {}

class MockIsNotificationCaptureSupported extends Mock
    implements IsNotificationCaptureSupported {}

class MockIsNotificationAccessGranted extends Mock
    implements IsNotificationAccessGranted {}

class MockGetIssuerApps extends Mock implements GetIssuerApps {}

class MockSnoozeCaptureBackgroundAlert extends Mock
    implements SnoozeCaptureBackgroundAlert {}

class MockRequestBatteryOptimizationExemption extends Mock
    implements RequestBatteryOptimizationExemption {}

class MockOpenCaptureAutostartSettings extends Mock
    implements OpenCaptureAutostartSettings {}

class MockMarkCaptureConfigured extends Mock implements MarkCaptureConfigured {}

class MockWatchIncomingCaptures extends Mock implements WatchIncomingCaptures {}

class MockDrainAndIngestCaptures extends Mock
    implements DrainAndIngestCaptures {}

/// The page-level fake for the HU-09 cubit: `NoticesPage` only reads the
/// snapshot, so a mocked `state` is enough for its widget and golden tests.
class MockCaptureBackgroundCubit extends MockCubit<CaptureBackgroundState>
    implements CaptureBackgroundCubit {}

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
  registerFallbackValue(const CaptureDiagnostics.empty());
}

/// A fixed non-null instant used as the builder default for
/// "the listener did connect". Only its non-nullness matters in the default
/// case; tests that exercise the connection windows pass their own instant.
const int defaultListenerConnectedAtEpochMs = 1789000000000;

/// The device facts HU-09 decides from, with every field overridable so each
/// test states only the value it is about.
///
/// The listener defaults to "connected just now": the heartbeat tests must opt
/// in to the degraded connection states, so the older diagnostics fixtures stay
/// calm instead of turning degraded by accident.
CaptureDiagnostics buildCaptureDiagnostics({
  int? lastCaptureAtEpochMs,
  int? lastListenerConnectedAtEpochMs = defaultListenerConnectedAtEpochMs,
  bool listenerConnectedNow = true,
  bool batteryOptimizationExempt = false,
  String manufacturer = 'Google',
  bool autostartAvailable = false,
}) =>
    CaptureDiagnostics(
      lastCaptureAtEpochMs: lastCaptureAtEpochMs,
      lastListenerConnectedAt: lastListenerConnectedAtEpochMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastListenerConnectedAtEpochMs),
      listenerConnectedNow: listenerConnectedNow,
      batteryOptimizationExempt: batteryOptimizationExempt,
      manufacturer: manufacturer,
      autostartAvailable: autostartAvailable,
    );

/// A health snapshot, for consumers that only read the decision.
CaptureBackgroundHealth buildCaptureBackgroundHealth({
  CaptureDiagnostics? diagnostics,
  bool degraded = false,
  DateTime? snoozedUntil,
  bool showsAttention = false,
}) =>
    CaptureBackgroundHealth(
      diagnostics: diagnostics ?? const CaptureDiagnostics.empty(),
      degraded: degraded,
      snoozedUntil: snoozedUntil,
      showsAttention: showsAttention,
    );

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
