import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_card_shell.dart';
import 'package:billetudo/features/capture/presentation/widgets/grouped_capture_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../capture_mocks.dart';

/// `RSizy` — the wallet+bank grouped capture (HU-07, high confidence).
/// Grouping is not confirming: this card keeps every "not money yet"
/// guarantee a lone capture has.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SizedBox(width: 350, child: child)),
      );

  CaptureReviewItem groupedItem() => CaptureReviewItem(
        capture: buildPendingCapture(
          merchantRaw: null,
          accountHint: '4417',
          amountMinor: 1870000,
        ),
        accountName: 'Bancolombia *4417',
        issuerName: 'Bancolombia',
        group: const CaptureGroupView(
          merchantRaw: 'CAFETERIA LA ESPIGA',
          walletIssuerName: 'Google Wallet',
          bankIssuerName: 'Bancolombia',
        ),
      );

  testWidgets('shows the merchant from the wallet leg and the source strip',
      (tester) async {
    await tester.pumpWidget(
      appWith(GroupedCaptureCard(item: groupedItem(), onTap: () {})),
    );

    expect(find.text('CAFETERIA LA ESPIGA'), findsOneWidget);
    expect(
      find.text('Un solo pago · Google Wallet + Bancolombia'),
      findsOneWidget,
    );
    expect(find.text('No suma a tu saldo'), findsOneWidget);
  });

  testWidgets(
      'is tappable end to end with a chevron, unlike the duplicate card',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      appWith(GroupedCaptureCard(item: groupedItem(), onTap: () => taps++)),
    );

    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    await tester.tap(find.byType(CaptureCardShell));
    expect(taps, 1);
  });

  testWidgets('keeps the ordinary rail color, never the amber duplicate one',
      (tester) async {
    await tester.pumpWidget(
      appWith(GroupedCaptureCard(item: groupedItem(), onTap: () {})),
    );

    final shell = tester.widget<CaptureCardShell>(
      find.byType(CaptureCardShell),
    );
    final colors = AppTheme.light().extension<AppColors>()!;
    expect(shell.railColor, colors.primaryOnSoft);
    expect(shell.railColor, isNot(colors.amberText));
  });

  testWidgets('never invents a merchant when neither leg carried one',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        GroupedCaptureCard(
          item: CaptureReviewItem(
            capture: buildPendingCapture(merchantRaw: null),
            group: const CaptureGroupView(),
          ),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Movimiento sin descripción'), findsOneWidget);
  });
}
