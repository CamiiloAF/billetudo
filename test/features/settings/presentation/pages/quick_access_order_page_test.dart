import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/home/domain/entities/quick_access_item.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:billetudo/features/settings/presentation/pages/quick_access_order_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../auth/presentation/widgets/pump_widget.dart';

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

void main() {
  late MockAppSettingsCubit cubit;

  setUp(() {
    cubit = MockAppSettingsCubit();
    when(() => cubit.state).thenReturn(const AppSettingsState());
    when(() => cubit.setQuickAccessOrder(any()))
        .thenAnswer((_) async => const Right(unit));
  });

  Future<void> pump(WidgetTester tester, AppSettingsState state) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<AppSettingsState>.empty(),
        initialState: state);
    await tester.pumpAuthWidget(
      BlocProvider<AppSettingsCubit>.value(
        value: cubit,
        child: const QuickAccessOrderPage(),
      ),
      wrapInScaffold: false,
    );
  }

  testWidgets(
      'renderiza los 5 accesos rápidos en el orden persistido en '
      'AppSettingsCubit', (tester) async {
    await pump(
      tester,
      const AppSettingsState(
        settings: AppSettings(
          zeroBasedEnabled: false,
          categoriesSeeded: true,
          onboardingCompleted: true,
        ),
      ),
    );

    expect(find.byType(QuickAccessOrderRow), findsNWidgets(5));

    final rows = tester
        .widgetList<QuickAccessOrderRow>(find.byType(QuickAccessOrderRow))
        .toList();
    expect(rows.map((r) => r.item).toList(), QuickAccessItem.defaultOrder);
  });

  testWidgets(
      'reordenar la lista invoca AppSettingsCubit.setQuickAccessOrder con '
      'la nueva permutación', (tester) async {
    await pump(
      tester,
      const AppSettingsState(
        settings: AppSettings(
          zeroBasedEnabled: false,
          categoriesSeeded: true,
          onboardingCompleted: true,
        ),
      ),
    );

    // Drives the widget's own reorder callback directly: exercising the
    // real long-press drag gesture belongs to the router/e2e layer, this
    // covers the persistence contract itself (criterion 5) — move Deudas
    // (index 2 of the default order) to the front.
    final reorderable = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderable.onReorder(2, 0);
    await tester.pump();

    verify(
      () => cubit.setQuickAccessOrder(const [
        QuickAccessItem.debts,
        QuickAccessItem.scheduledPayments,
        QuickAccessItem.accounts,
        QuickAccessItem.reports,
        QuickAccessItem.goals,
      ]),
    ).called(1);
  });
}
