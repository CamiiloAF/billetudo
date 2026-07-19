import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_category_tiles.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryQuickPickerCubit extends MockCubit<CategoryQuickPickerState>
    implements CategoryQuickPickerCubit {}

void main() {
  late MockCategoryQuickPickerCubit cubit;

  final ocio = Category(
    id: 'cat-1',
    name: 'Ocio',
    kind: CategoryKind.expense,
    icon: 'party-popper',
    sortOrder: 0,
    createdAt: DateTime(2026),
    updatedAt: 0,
  );
  final hogar = Category(
    id: 'cat-2',
    name: 'Hogar',
    kind: CategoryKind.expense,
    icon: 'home',
    sortOrder: 1,
    createdAt: DateTime(2026),
    updatedAt: 0,
  );

  setUpAll(() {
    registerFallbackValue(CategoryKind.expense);
  });

  setUp(() {
    cubit = MockCategoryQuickPickerCubit();
    when(
      () => cubit.start(
          kind: any(named: 'kind'), selectedId: any(named: 'selectedId')),
    ).thenAnswer((_) async {});
    when(() => cubit.setKind(any(), selectedId: any(named: 'selectedId')))
        .thenAnswer((_) async {});
    when(() => cubit.syncSelection(any())).thenAnswer((_) async {});
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<CategoryQuickPickerState>.empty());

    getIt.registerFactory<CategoryQuickPickerCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  Future<void> pumpTiles(
    WidgetTester tester, {
    required CategoryQuickPickerState state,
    String? selectedId,
    ValueChanged<Category>? onSelected,
    Brightness brightness = Brightness.light,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScheduledPaymentCategoryTiles(
            kind: CategoryKind.expense,
            selectedId: selectedId,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('pinta un tile por cada categoría más usada, más el tile "Otra"',
      (tester) async {
    await pumpTiles(
      tester,
      state: CategoryQuickPickerState(
        status: CategoryQuickPickerStatus.ready,
        mostUsed: [ocio, hogar],
      ),
    );

    expect(find.byType(ScheduledPaymentCategoryTile), findsNWidgets(3));
    expect(find.text('Ocio'), findsOneWidget);
    expect(find.text('Hogar'), findsOneWidget);
    expect(find.text('Otra'), findsOneWidget);
    expect(find.byIcon(LucideIcons.ellipsis), findsOneWidget);
  });

  testWidgets('el tile de la categoría seleccionada usa el color textPrimary',
      (tester) async {
    await pumpTiles(
      tester,
      state: CategoryQuickPickerState(
        status: CategoryQuickPickerStatus.ready,
        mostUsed: [ocio, hogar],
        selected: ocio,
      ),
      selectedId: ocio.id,
    );

    final selectedTile = tester.widget<ScheduledPaymentCategoryTile>(
      find.widgetWithText(ScheduledPaymentCategoryTile, 'Ocio'),
    );
    expect(selectedTile.selected, isTrue);

    final label = tester.widget<Text>(find.text('Ocio'));
    expect(label.style?.color, AppColors.light.textPrimary);
  });

  testWidgets('tocar un tile reporta la categoría vía onSelected',
      (tester) async {
    Category? picked;
    await pumpTiles(
      tester,
      state: CategoryQuickPickerState(
        status: CategoryQuickPickerStatus.ready,
        mostUsed: [ocio, hogar],
      ),
      onSelected: (category) => picked = category,
    );

    await tester.tap(find.text('Hogar'));
    await tester.pump();

    expect(picked, hogar);
    verify(() => cubit.select(hogar)).called(1);
  });

  testWidgets(
      'tema oscuro: el tile seleccionado resuelve textPrimary/primarySoft de AppColors.dark',
      (tester) async {
    await pumpTiles(
      tester,
      state: CategoryQuickPickerState(
        status: CategoryQuickPickerStatus.ready,
        mostUsed: [ocio, hogar],
        selected: ocio,
      ),
      selectedId: ocio.id,
      brightness: Brightness.dark,
    );

    final label = tester.widget<Text>(find.text('Ocio'));
    expect(label.style?.color, AppColors.dark.textPrimary);
    expect(label.style?.color, isNot(AppColors.light.textPrimary));

    final selectedTileContainer = tester
        .widgetList<Container>(
          find.descendant(
            of: find.widgetWithText(ScheduledPaymentCategoryTile, 'Ocio'),
            matching: find.byType(Container),
          ),
        )
        .first;
    final decoration = selectedTileContainer.decoration! as BoxDecoration;
    expect(decoration.color, isNot(AppColors.light.primarySoft));
  });

  testWidgets(
      'tema oscuro: el tile no seleccionado resuelve textSecondary/muted de AppColors.dark',
      (tester) async {
    await pumpTiles(
      tester,
      state: CategoryQuickPickerState(
        status: CategoryQuickPickerStatus.ready,
        mostUsed: [ocio, hogar],
      ),
      brightness: Brightness.dark,
    );

    final label = tester.widget<Text>(find.text('Hogar'));
    expect(label.style?.color, AppColors.dark.textSecondary);
    expect(label.style?.color, isNot(AppColors.light.textSecondary));

    final tileContainer = tester
        .widgetList<Container>(
          find.descendant(
            of: find.widgetWithText(ScheduledPaymentCategoryTile, 'Hogar'),
            matching: find.byType(Container),
          ),
        )
        .first;
    final decoration = tileContainer.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.dark.muted);
    expect(decoration.color, isNot(AppColors.light.muted));
  });
}
