import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_card_shell.dart';
import 'package:billetudo/features/capture/presentation/widgets/pending_capture_card.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../capture_mocks.dart';

/// `skjlg` — the Avisos-centre capture card. Five redundant signals say this
/// is not money; these tests keep them from drifting silently.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SizedBox(width: 350, child: child)),
      );

  CaptureReviewItem itemWith({
    TransactionType entryType = TransactionType.expense,
    String? merchantRaw = 'TIENDA D1 SANTA ROSA',
    String? accountName = 'Cuenta Nu',
    String? issuerName = 'Nu',
  }) =>
      CaptureReviewItem(
        capture: buildPendingCapture(
          entryType: entryType,
          merchantRaw: merchantRaw,
          amountMinor: 5847000,
        ),
        accountName: accountName,
        issuerName: issuerName,
      );

  testWidgets('carries the kicker and the issuer line, no button',
      (tester) async {
    await tester.pumpWidget(
      appWith(PendingCaptureCard(item: itemWith(), onTap: () {})),
    );

    expect(find.text('No suma a tu saldo'), findsOneWidget);
    expect(find.text('Aviso de Nu'), findsOneWidget);
    expect(find.text('Confirmar'), findsNothing);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });

  testWidgets('the whole card is the tap target', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      appWith(PendingCaptureCard(item: itemWith(), onTap: () => taps++)),
    );

    await tester.tap(find.byType(CaptureCardShell));
    expect(taps, 1);
  });

  testWidgets('the amount is attenuated and an expense carries no minus sign',
      (tester) async {
    await tester.pumpWidget(
      appWith(PendingCaptureCard(item: itemWith(), onTap: () {})),
    );

    final amount = tester.widget<Text>(find.text(r'$58.470'));
    final colors = AppTheme.light().extension<AppColors>()!;
    expect(amount.style?.color, colors.textSecondary);
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
  });

  testWidgets('a long merchant name truncates instead of overflowing',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        PendingCaptureCard(
          item: itemWith(
            merchantRaw: 'GRANERO Y SUPERMERCADO LA ESPERANZA DEL '
                'NORTE SAS SUCURSAL POBLADO',
          ),
          onTap: () {},
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

  testWidgets('hides the issuer line rather than printing an empty one',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        PendingCaptureCard(item: itemWith(issuerName: null), onTap: () {}),
      ),
    );

    expect(find.textContaining('Aviso de'), findsNothing);
  });
}
