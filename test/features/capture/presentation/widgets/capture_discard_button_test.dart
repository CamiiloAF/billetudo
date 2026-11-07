import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_discard_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Avisos centre's per-card discard affordance. Its contract is small but
/// load-bearing: a real 44x44 tap target (the card below it is tappable end to
/// end, so a painted glyph would turn near-misses into "open the form"), the
/// localized tooltip, and the quiet `$text-secondary` treatment of an
/// undoable action.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('offers a 44x44 tap target with the localized tooltip',
      (tester) async {
    await tester.pumpWidget(appWith(CaptureDiscardButton(onPressed: () {})));

    final button = find.byType(IconButton);
    expect(button, findsOneWidget);
    expect(tester.getSize(button), const Size(44, 44));
    expect(find.byIcon(LucideIcons.x), findsOneWidget);
    expect(find.byTooltip('Descartar captura'), findsOneWidget);
  });

  testWidgets('is painted quiet, never with the destructive red',
      (tester) async {
    await tester.pumpWidget(appWith(CaptureDiscardButton(onPressed: () {})));

    final colors = AppTheme.light().extension<AppColors>()!;
    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.x));
    // `IconButton.styleFrom(foregroundColor:)` colors the icon; asserting the
    // resolved color through the rendered widget keeps this honest if the
    // style is refactored.
    final iconTheme = IconTheme.of(
      tester.element(find.byIcon(LucideIcons.x)),
    );
    final painted = icon.color ?? iconTheme.color;
    expect(painted, colors.textSecondary);
    expect(painted, isNot(colors.expense));
  });

  testWidgets('calls its callback exactly once, and nothing else',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      appWith(CaptureDiscardButton(onPressed: () => taps++)),
    );

    await tester.tap(find.byType(IconButton));
    expect(taps, 1);
  });
}
