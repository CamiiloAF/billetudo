import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance_adjustment.dart';
import 'package:billetudo/features/accounts/domain/usecases/adjust_account_balance.dart';
import 'package:billetudo/features/accounts/presentation/cubit/adjust_balance_cubit.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/adjust_balance_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../account_fixtures.dart';

class MockAdjustAccountBalance extends Mock implements AdjustAccountBalance {}

/// Golden coverage for the new "Ajustar saldo" sheet (Mejora #1): its plain
/// vs. card copy and its two selectable modes, in both themes. Uses a real
/// `AdjustBalanceCubit` over a mocked use case (the sheet is pure render here),
/// shown through the app's own bottom-sheet chrome instead of `getIt`.
void main() {
  late MockAdjustAccountBalance adjust;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
    registerFallbackValue(buildAccount());
    registerFallbackValue(BalanceAdjustmentMode.registerMovement);
  });

  setUp(() {
    adjust = MockAdjustAccountBalance();
    when(
      () => adjust(
        account: any(named: 'account'),
        currentBalanceMinor: any(named: 'currentBalanceMinor'),
        newDisplayedBalanceMinor: any(named: 'newDisplayedBalanceMinor'),
        mode: any(named: 'mode'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required void Function(AdjustBalanceCubit cubit) seed,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BottomSheetBase.show<void>(
              context,
              builder: (_) => BlocProvider(
                create: (_) {
                  final cubit = AdjustBalanceCubit(adjust);
                  seed(cubit);
                  return cubit;
                },
                child: const AdjustBalanceSheet(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_adjust_balance_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('plain account, register mode, +figure ($suffix)', (
      tester,
    ) async {
      await golden(
        tester,
        'plain_register_$suffix',
        brightness: brightness,
        seed: (cubit) => cubit
          ..start(
            account: buildAccount(initialBalanceMinor: 0),
            currentBalanceMinor: 218000000,
          )
          ..newBalanceChanged('2500000'),
      );
    });

    testWidgets('plain account, correct-initial mode selected ($suffix)', (
      tester,
    ) async {
      await golden(
        tester,
        'plain_correct_$suffix',
        brightness: brightness,
        seed: (cubit) => cubit
          ..start(
            account: buildAccount(initialBalanceMinor: 0),
            currentBalanceMinor: 218000000,
          )
          ..newBalanceChanged('2500000')
          ..modeSelected(BalanceAdjustmentMode.correctInitial),
      );
    });

    testWidgets('card names its debt ($suffix)', (tester) async {
      await golden(
        tester,
        'card_debt_$suffix',
        brightness: brightness,
        seed: (cubit) => cubit
          ..start(
            account: buildCard(
              creditLimitMinor: 300000000,
              initialBalanceMinor: -100000,
            ),
            currentBalanceMinor: -100000,
          )
          ..newBalanceChanged('150000'),
      );
    });
  }
}
