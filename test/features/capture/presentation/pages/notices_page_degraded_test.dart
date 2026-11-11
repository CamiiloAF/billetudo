import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_state.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/cubit/notices_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/notices_state.dart';
import 'package:billetudo/features/capture/presentation/pages/notices_page.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_degraded_card.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_degraded_empty_view.dart';
import 'package:billetudo/features/capture/presentation/widgets/pending_capture_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

class MockNoticesCubit extends MockCubit<NoticesState>
    implements NoticesCubit {}

/// HU-09's integration in Avisos: the degraded card sits above the captures
/// section (with its "última captura" footer), the degraded empty state
/// replaces "Todo al día", and without attention the screen is exactly what it
/// was before.
void main() {
  late MockNoticesCubit notices;
  late MockCaptureBackgroundCubit background;

  setUpAll(registerCaptureFallbacks);

  setUp(() {
    notices = MockNoticesCubit();
    background = MockCaptureBackgroundCubit();
    when(() => background.snooze()).thenAnswer((_) async {});
  });

  CaptureReviewItem item(String id) => CaptureReviewItem(
        capture: buildPendingCapture(id: id, merchantRaw: 'TIENDA D1'),
        accountName: 'Cuenta Nu',
        issuerName: 'Nu',
      );

  CaptureBackgroundState attention({DateTime? lastCaptureAt}) =>
      CaptureBackgroundState(
        isSupported: true,
        isLoading: false,
        showsAttention: true,
        permissionGranted: true,
        enabledCount: 1,
        diagnostics: buildCaptureDiagnostics(
          manufacturer: 'Xiaomi',
          autostartAvailable: true,
          lastCaptureAtEpochMs: (lastCaptureAt ?? DateTime(2026, 8, 7, 9, 19))
              .millisecondsSinceEpoch,
        ),
      );

  const CaptureBackgroundState calm =
      CaptureBackgroundState(isSupported: true, isLoading: false);

  Future<void> pumpPage(
    WidgetTester tester, {
    required NoticesState noticesState,
    required CaptureBackgroundState backgroundState,
    bool captureSupported = true,
  }) async {
    when(() => notices.state).thenReturn(noticesState);
    when(() => background.state).thenReturn(backgroundState);
    await withClock(Clock.fixed(DateTime(2026, 8, 7, 12)), () async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<NoticesCubit>.value(value: notices),
              BlocProvider<CaptureBackgroundCubit>.value(value: background),
            ],
            child: NoticesPage(
              onDispatchCapture: (_) {},
              onChooseIssuers: () {},
              captureSupported: captureSupported,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  }

  testWidgets('with captures, the degraded card sits above the section rows',
      (tester) async {
    await pumpPage(
      tester,
      noticesState: NoticesState(
        status: NoticesStatus.ready,
        captures: [item('capture-1')],
      ),
      backgroundState: attention(),
    );

    expect(find.byType(CaptureDegradedCard), findsOneWidget);
    expect(find.textContaining('Última captura:'), findsOneWidget);
    expect(find.text('TIENDA D1'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(CaptureDegradedCard)).dy,
      lessThan(tester.getTopLeft(find.byType(PendingCaptureCard)).dy),
    );
  });

  testWidgets(
      'with a degraded section but no capture ever received, the footer says '
      'so instead of inventing a date', (tester) async {
    final CaptureBackgroundState noHistory = CaptureBackgroundState(
      isSupported: true,
      isLoading: false,
      showsAttention: true,
      permissionGranted: true,
      enabledCount: 1,
      diagnostics: buildCaptureDiagnostics(
        manufacturer: 'Xiaomi',
        autostartAvailable: true,
      ),
    );

    await pumpPage(
      tester,
      noticesState: NoticesState(
        status: NoticesStatus.ready,
        captures: [item('capture-1')],
      ),
      backgroundState: noHistory,
    );

    expect(find.byType(CaptureDegradedCard), findsOneWidget);
    expect(
      find.text('Todavía no recibimos ningún aviso.'),
      findsOneWidget,
    );
    expect(find.textContaining('Última captura:'), findsNothing);
  });

  testWidgets('without attention the card and the footer do not exist',
      (tester) async {
    await pumpPage(
      tester,
      noticesState: NoticesState(
        status: NoticesStatus.ready,
        captures: [item('capture-1')],
      ),
      backgroundState: calm,
    );

    expect(find.byType(CaptureDegradedCard), findsNothing);
    expect(find.textContaining('Última captura:'), findsNothing);
    expect(find.byType(PendingCaptureCard), findsOneWidget);
  });

  testWidgets('"Ahora no" on the card snoozes through the background cubit',
      (tester) async {
    await pumpPage(
      tester,
      noticesState: NoticesState(
        status: NoticesStatus.ready,
        captures: [item('capture-1')],
      ),
      backgroundState: attention(),
    );

    await tester.tap(find.text('Ahora no'));
    await tester.pump();

    verify(() => background.snooze()).called(1);
  });

  testWidgets(
      'with nothing to review the degraded empty state replaces '
      '"Todo al día"', (tester) async {
    await pumpPage(
      tester,
      noticesState: const NoticesState(
        status: NoticesStatus.ready,
        captures: [],
      ),
      backgroundState: attention(),
    );

    expect(find.byType(CaptureDegradedEmptyView), findsOneWidget);
    expect(find.text('Puede que los avisos no estén llegando'), findsOneWidget);
    expect(find.text('Todo al día'), findsNothing);
    // Never both surfaces at once.
    expect(find.byType(CaptureDegradedCard), findsNothing);
  });

  testWidgets('without attention the ordinary "Todo al día" stays',
      (tester) async {
    await pumpPage(
      tester,
      noticesState: const NoticesState(
        status: NoticesStatus.ready,
        captures: [],
      ),
      backgroundState: calm,
    );

    expect(find.text('Todo al día'), findsOneWidget);
    expect(find.byType(CaptureDegradedEmptyView), findsNothing);
  });

  testWidgets('the permission/issuer empty states keep their precedence',
      (tester) async {
    await pumpPage(
      tester,
      noticesState: const NoticesState(
        status: NoticesStatus.ready,
        captures: [],
        hasEnabledIssuers: false,
      ),
      // Contradictory on purpose: even if the cubit claimed attention, the
      // "elige apps" state must win.
      backgroundState: attention(),
    );

    expect(find.text('Todavía no escuchamos ninguna app'), findsOneWidget);
    expect(find.byType(CaptureDegradedEmptyView), findsNothing);
  });

  testWidgets('"Revisar" opens the shared background sheet', (tester) async {
    await pumpPage(
      tester,
      noticesState: NoticesState(
        status: NoticesStatus.ready,
        captures: [item('capture-1')],
      ),
      backgroundState: attention(),
    );

    await tester.tap(find.text('Revisar'));
    await tester.pumpAndSettle();

    expect(find.text('Captura en segundo plano'), findsOneWidget);
  });

  testWidgets('"Revisar captura" opens the same sheet from the empty state',
      (tester) async {
    await pumpPage(
      tester,
      noticesState: const NoticesState(
        status: NoticesStatus.ready,
        captures: [],
      ),
      backgroundState: attention(),
    );

    await tester.tap(find.text('Revisar captura'));
    await tester.pumpAndSettle();

    expect(find.text('Captura en segundo plano'), findsOneWidget);
  });

  testWidgets(
      'the background settings link is available even with nothing to review',
      (tester) async {
    // The user's requirement: the permanent door must not depend on a pending
    // capture (nor on the degraded state) existing.
    await pumpPage(
      tester,
      noticesState: const NoticesState(
        status: NoticesStatus.ready,
        captures: [],
      ),
      backgroundState: const CaptureBackgroundState(
        isSupported: true,
        isLoading: false,
        permissionGranted: true,
        enabledCount: 2,
      ),
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(NoticesPage)),
    );
    expect(find.text(l10n.captureBackgroundLinkLabel), findsOneWidget);
  });
}
