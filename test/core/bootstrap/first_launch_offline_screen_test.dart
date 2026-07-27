import 'package:billetudo/core/bootstrap/first_launch_offline_cubit.dart';
import 'package:billetudo/core/bootstrap/first_launch_offline_screen.dart';
import 'package:billetudo/core/bootstrap/first_launch_offline_state.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

class MockFirstLaunchOfflineCubit extends MockCubit<FirstLaunchOfflineState>
    implements FirstLaunchOfflineCubit {}

void main() {
  late MockFirstLaunchOfflineCubit cubit;

  setUp(() {
    cubit = MockFirstLaunchOfflineCubit();
  });

  Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<FirstLaunchOfflineCubit>.value(
            value: cubit,
            child: const FirstLaunchOfflineScreen(),
          ),
        ),
      );

  testWidgets(
      'estado idle: muestra el copy agnóstico, icono y botón habilitado',
      (tester) async {
    when(() => cubit.state).thenReturn(const FirstLaunchOfflineState());

    await pumpScreen(tester);

    expect(find.text('Conéctate para continuar'), findsOneWidget);
    expect(
      find.textContaining('Necesitamos conexión a internet'),
      findsOneWidget,
    );
    expect(find.byIcon(LucideIcons.wifiOff), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Reintentando...'), findsNothing);

    final button = tester.widget<FilledButton>(
      find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('tocar Reintentar llama a cubit.retry()', (tester) async {
    when(() => cubit.state).thenReturn(const FirstLaunchOfflineState());
    when(() => cubit.retry()).thenAnswer((_) async {});

    await pumpScreen(tester);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    verify(() => cubit.retry()).called(1);
  });

  testWidgets('estado retrying: botón deshabilitado con label y spinner',
      (tester) async {
    when(() => cubit.state).thenReturn(
      const FirstLaunchOfflineState(status: FirstLaunchOfflineStatus.retrying),
    );

    await pumpScreen(tester);

    expect(find.text('Reintentando...'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    expect(button.onPressed, isNull);
  });
}
