import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/accounts/domain/entities/account_deletion_impact.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/cannot_delete_last_account_sheet.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/confirm_archive_account_sheet.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/confirm_delete_account_sheet.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/confirm_type_or_currency_change_sheet.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/currency_picker_sheet.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/day_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  /// Opens [openSheet] through a real trigger button (mirrors how a sheet
  /// actually reaches the screen — scrim, drag handle and the `[28,28,0,0]`
  /// bottom sheet theme included) and captures the whole screen.
  Future<void> golden(
    WidgetTester tester,
    Future<void> Function(BuildContext context) openSheet,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openSheet(context),
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
      matchesGoldenFile('goldens/sheet_$name.png'),
    );
  }

  const impact = AccountDeletionImpact(
    transactionCount: 12,
    goalCount: 0,
    debtCount: 0,
    isLastAccount: false,
  );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('confirm delete, with transactions ($suffix)',
        (tester) async {
      await golden(
        tester,
        (context) => ConfirmDeleteAccountSheet.show(context, impact: impact),
        'confirm_delete_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('confirm archive ($suffix)', (tester) async {
      await golden(
        tester,
        ConfirmArchiveAccountSheet.show,
        'confirm_archive_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('confirm type or currency change ($suffix)', (tester) async {
      await golden(
        tester,
        ConfirmTypeOrCurrencyChangeSheet.show,
        'confirm_type_or_currency_change_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('cannot delete the last account ($suffix)', (tester) async {
      await golden(
        tester,
        CannotDeleteLastAccountSheet.show,
        'cannot_delete_last_account_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('currency picker ($suffix)', (tester) async {
      await golden(
        tester,
        (context) => CurrencyPickerSheet.show(context, selected: 'COP'),
        'currency_picker_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('day picker ($suffix)', (tester) async {
      await golden(
        tester,
        (context) => DayPickerSheet.show(
          context,
          title: AppLocalizations.of(context).accountFormStatementDayLabel,
          selected: 15,
        ),
        'day_picker_$suffix',
        brightness: brightness,
      );
    });
  }
}
