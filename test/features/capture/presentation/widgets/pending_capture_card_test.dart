import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_status_pill.dart';
import 'package:billetudo/features/capture/presentation/widgets/duplicate_compare_card.dart';
import 'package:billetudo/features/capture/presentation/widgets/duplicate_compare_strip.dart';
import 'package:billetudo/features/capture/presentation/widgets/pending_capture_card.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../capture_mocks.dart';

/// A pending capture is NOT money. The design carries five redundant signals
/// that say so, and each one was audited individually — these tests exist so
/// none of them can be dropped silently on either surface.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  CaptureReviewItem itemWith({
    TransactionType entryType = TransactionType.expense,
    String? merchantRaw = 'TIENDA D1 SANTA ROSA',
    String? accountName = 'Cuenta Nu',
  }) =>
      CaptureReviewItem(
        capture: buildPendingCapture(
          entryType: entryType,
          merchantRaw: merchantRaw,
          amountMinor: 5847000,
        ),
        accountName: accountName,
        issuerName: 'Nu',
      );

  testWidgets('carries the pill, the bell tile and the issuer line',
      (tester) async {
    await tester.pumpWidget(
      appWith(PendingCaptureCard(item: itemWith(), onTap: () {})),
    );

    expect(find.byType(CaptureStatusPill), findsOneWidget);
    expect(find.text('No suma a tu saldo'), findsOneWidget);
    expect(find.byIcon(LucideIcons.bellRing), findsOneWidget);
    expect(find.text('Aviso de Nu'), findsOneWidget);
  });

  testWidgets('the amount is attenuated and an expense carries no minus sign',
      (tester) async {
    await tester.pumpWidget(
      appWith(PendingCaptureCard(item: itemWith(), onTap: () {})),
    );

    final amount = tester.widget<Text>(find.text(r'$58.470'));
    final colors = AppTheme.light().extension<AppColors>()!;
    expect(amount.style?.color, colors.textSecondary);
    // A `-` would read as money already subtracted, which it is not.
    expect(find.text(r'-$58.470'), findsNothing);
  });

  testWidgets('an income keeps its plus sign but stays attenuated',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        PendingCaptureCard(
          item: itemWith(entryType: TransactionType.income),
          onTap: () {},
        ),
      ),
    );

    final amount = tester.widget<Text>(find.text(r'+$58.470'));
    final colors = AppTheme.light().extension<AppColors>()!;
    expect(amount.style?.color, colors.textSecondary);
    expect(amount.style?.color, isNot(colors.incomeText));
    expect(find.byIcon(LucideIcons.arrowDownLeft), findsOneWidget);
  });

  testWidgets('the movements-list variant drops the action but keeps the pill',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        PendingCaptureCard(
          item: itemWith(),
          showAction: false,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Confirmar'), findsNothing);
    // The critical signal must NOT degrade where it lives beside real money.
    expect(find.byType(CaptureStatusPill), findsOneWidget);
    expect(find.text('No suma a tu saldo'), findsOneWidget);
  });

  testWidgets('a long merchant name truncates instead of overflowing',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        SizedBox(
          width: 350,
          child: PendingCaptureCard(
            item: itemWith(
              merchantRaw: 'GRANERO Y SUPERMERCADO LA ESPERANZA DEL '
                  'NORTE SAS SUCURSAL POBLADO',
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    final merchant = tester.widget<Text>(
      find.textContaining('GRANERO Y SUPERMERCADO'),
    );
    expect(merchant.maxLines, 1);
    expect(merchant.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a capture with no suggested account says so, never a fake one',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        PendingCaptureCard(item: itemWith(accountName: null), onTap: () {}),
      ),
    );

    expect(find.textContaining('Sin cuenta'), findsOneWidget);
  });

  group('possible duplicate', () {
    CaptureReviewItem duplicateItem() => CaptureReviewItem(
          capture: buildPendingCapture(amountMinor: 11525000),
          accountName: 'Cuenta Nu',
          issuerName: 'Nu',
          duplicate: CaptureDuplicateView(
            transactionId: 'tx-1',
            amountMinor: 11525000,
            currency: 'COP',
            type: TransactionType.expense,
            date: DateTime(2026, 9, 1, 11, 9),
            title: 'Mercado de la semana',
            accountName: 'Cuenta Nu',
            categoryIcon: 'shopping-cart',
            categoryColor: 'mint',
          ),
        );

    testWidgets('offers both answers with exactly the same visual weight',
        (tester) async {
      await tester.pumpWidget(
        appWith(
          SizedBox(
            width: 350,
            child: DuplicateCompareCard(
              item: duplicateItem(),
              onSame: () {},
              onDifferent: () {},
            ),
          ),
        ),
      );

      final buttons = tester
          .widgetList<DuplicateActionButton>(
            find.byType(DuplicateActionButton),
          )
          .toList();
      expect(buttons, hasLength(2));
      expect(find.text('Es la misma'), findsOneWidget);
      expect(find.text('Es otra compra'), findsOneWidget);

      // Same rendered width: neither answer may be nudged by layout.
      final sizes = tester
          .widgetList<Material>(
            find.descendant(
              of: find.byType(DuplicateActionButton),
              matching: find.byType(Material),
            ),
          )
          .toList();
      expect(sizes, hasLength(2));
      final first = tester.getSize(find.byType(DuplicateActionButton).first);
      final second = tester.getSize(find.byType(DuplicateActionButton).last);
      expect(first.width, second.width);

      // Same label colour, and neither is the brand violet that used to push
      // the user towards discarding.
      final colors = AppTheme.light().extension<AppColors>()!;
      final same = tester.widget<Text>(find.text('Es la misma'));
      final other = tester.widget<Text>(find.text('Es otra compra'));
      expect(same.style?.color, other.style?.color);
      expect(same.style?.color, colors.textPrimary);
      expect(same.style?.fontWeight, other.style?.fontWeight);
    });

    testWidgets('marks the duplicate in amber, never in the expense red',
        (tester) async {
      await tester.pumpWidget(
        appWith(
          SizedBox(
            width: 350,
            child: DuplicateCompareCard(
              item: duplicateItem(),
              onSame: () {},
              onDifferent: () {},
            ),
          ),
        ),
      );

      final colors = AppTheme.light().extension<AppColors>()!;
      final label = tester.widget<Text>(find.text('Posible duplicado'));
      expect(label.style?.color, colors.amberText);
      expect(label.style?.color, isNot(colors.expense));
      expect(label.style?.color, isNot(colors.expenseText));
    });

    testWidgets('the compared movement is not tappable', (tester) async {
      await tester.pumpWidget(
        appWith(
          SizedBox(
            width: 350,
            child: DuplicateCompareCard(
              item: duplicateItem(),
              onSame: () {},
              onDifferent: () {},
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(DuplicateCompareStrip),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('neither answer fires on its own', (tester) async {
      var same = 0;
      var different = 0;
      await tester.pumpWidget(
        appWith(
          SizedBox(
            width: 350,
            child: DuplicateCompareCard(
              item: duplicateItem(),
              onSame: () => same++,
              onDifferent: () => different++,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(same, 0);
      expect(different, 0);
    });
  });
}
