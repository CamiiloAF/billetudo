import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_issuers_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_issuers_state.dart';
import 'package:billetudo/features/capture/presentation/pages/capture_issuers_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCaptureIssuersCubit extends MockCubit<CaptureIssuersState>
    implements CaptureIssuersCubit {}

/// Regression: returning from the permission flow used to reuse a catalog
/// screen whose cubit had loaded before the permission existed, so every
/// switch looked off until the screen was re-entered. The page must re-read
/// the catalog after [CaptureIssuersPage.onOpenPermission] completes.
void main() {
  late MockCaptureIssuersCubit cubit;

  setUp(() {
    cubit = MockCaptureIssuersCubit();
    when(() => cubit.state).thenReturn(
      const CaptureIssuersState(isLoading: false, permissionGranted: false),
    );
    when(() => cubit.refresh()).thenAnswer((_) async {});
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required Future<void> Function() onOpenPermission,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<CaptureIssuersCubit>.value(
          value: cubit,
          child: CaptureIssuersPage(onOpenPermission: onOpenPermission),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('re-reads the catalog after the permission flow returns',
      (tester) async {
    var opened = 0;
    await pumpPage(
      tester,
      onOpenPermission: () async {
        opened++;
      },
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CaptureIssuersPage)),
    );
    await tester.tap(find.text(l10n.captureDisabledOpenSettingsCta));
    await tester.pumpAndSettle();

    expect(opened, 1);
    verify(() => cubit.refresh()).called(1);
  });

  testWidgets('the second link (how it works) also re-reads afterwards',
      (tester) async {
    var opened = 0;
    await pumpPage(
      tester,
      onOpenPermission: () async {
        opened++;
      },
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CaptureIssuersPage)),
    );
    await tester.tap(find.text(l10n.captureSeeHowItWorksCta));
    await tester.pumpAndSettle();

    expect(opened, 1);
    verify(() => cubit.refresh()).called(1);
  });
}
