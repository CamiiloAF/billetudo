import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_status_pill.dart';
import 'package:billetudo/features/capture/presentation/widgets/movement_pending_capture_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../capture_mocks.dart';

/// `vRWd5` — the pending-capture card for the movements ghost block. The
/// tint stays here on purpose, because it sits beside real money; this file
/// also protects the suggested-category chip's two variants.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SizedBox(width: 350, child: child)),
      );

  CaptureReviewItem itemWith({String? suggestedCategoryName}) =>
      CaptureReviewItem(
        capture: buildPendingCapture(amountMinor: 5847000),
        accountName: 'Cuenta Nu',
        issuerName: 'Nu',
        suggestedCategoryName: suggestedCategoryName,
      );

  testWidgets('keeps the tint, the bell tile and the pill', (tester) async {
    await tester.pumpWidget(
      appWith(MovementPendingCaptureCard(item: itemWith(), onTap: () {})),
    );

    final colors = AppTheme.light().extension<AppColors>()!;
    final card = tester.widget<Material>(
      find.descendant(
        of: find.byType(MovementPendingCaptureCard),
        matching: find.byType(Material),
      ),
    );
    expect(card.color, colors.primarySoft);
    expect(find.byType(CaptureStatusPill), findsOneWidget);
    expect(find.byIcon(LucideIcons.bellRing), findsOneWidget);
    expect(find.text('No suma a tu saldo'), findsOneWidget);
    // `w5AfEL`: "Confirmar ›" is a visual label, not a second tap target —
    // the whole card still carries the single `onTap` (see the test below).
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });

  testWidgets('shows the suggested-category chip when there is one',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        MovementPendingCaptureCard(
          item: itemWith(suggestedCategoryName: 'Mercado'),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Sugerida: Mercado'), findsOneWidget);
  });

  testWidgets('renders no chip and no gap when there is no suggestion yet',
      (tester) async {
    await tester.pumpWidget(
      appWith(MovementPendingCaptureCard(item: itemWith(), onTap: () {})),
    );

    expect(find.textContaining('Sugerida'), findsNothing);
  });

  testWidgets('the whole card is the tap target', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      appWith(
        MovementPendingCaptureCard(item: itemWith(), onTap: () => taps++),
      ),
    );

    await tester.tap(find.byType(InkWell));
    expect(taps, 1);
  });
}
