import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_state.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_background_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

/// The permanent entry into "Captura en segundo plano" from Avisos (HU-09):
/// a brand-new user who only granted notification access would otherwise
/// never learn that two system settings also matter.
void main() {
  late MockCaptureBackgroundCubit cubit;

  setUp(() {
    cubit = MockCaptureBackgroundCubit();
  });

  Future<void> pumpLink(
    WidgetTester tester, {
    required CaptureBackgroundState state,
    ValueChanged<bool>? onOpenSetup,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<CaptureBackgroundCubit>.value(
            value: cubit,
            child: CaptureBackgroundLink(
              onOpenSetup: onOpenSetup ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('is hidden on platforms without notification listeners',
      (tester) async {
    await pumpLink(tester, state: const CaptureBackgroundState());

    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('opens the permission/issuer setup when capture is not ready',
      (tester) async {
    final opened = <bool>[];
    await pumpLink(
      tester,
      state: const CaptureBackgroundState(
        isSupported: true,
        isLoading: false,
        permissionGranted: false,
      ),
      onOpenSetup: opened.add,
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CaptureBackgroundLink)),
    );
    await tester.tap(find.text(l10n.captureBackgroundLinkLabel));
    await tester.pumpAndSettle();

    expect(opened, <bool>[false]);
    expect(find.byType(BottomSheetBase), findsNothing);
  });

  testWidgets('opens the sheet once capture is configured', (tester) async {
    await pumpLink(
      tester,
      state: const CaptureBackgroundState(
        isSupported: true,
        isLoading: false,
        permissionGranted: true,
        enabledCount: 2,
      ),
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CaptureBackgroundLink)),
    );
    await tester.tap(find.text(l10n.captureBackgroundLinkLabel));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheetBase), findsOneWidget);
    expect(find.text(l10n.captureBackgroundSheetTitle), findsOneWidget);
  });
}
