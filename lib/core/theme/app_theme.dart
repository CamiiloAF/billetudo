import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Builds billetudo's light and dark [ThemeData] from the [AppColors] tokens
/// (a mirror of `billetudo.pen`). Radii and spacing follow
/// `design-system/billetudo/MASTER.md`.
abstract final class AppTheme {
  const AppTheme._();

  // Design system radii (MASTER.md → "Radios y espaciado").
  static const double radiusLarge = 24; // cards / hero / tab bar
  static const double radiusMedium = 16; // chips / buttons / icon-wrap
  static const double radiusField = 14; // form fields / segmented control
  static const double sheetRadius = 28; // bottom sheets (top corners)

  // Shared motion: the standard duration/curve for sober in-app transitions
  // (expand/collapse, size changes). Keep every animation on these so the app
  // feels of one piece.
  static const Duration motionDuration = Duration(milliseconds: 220);
  static const Curve motionCurve = Curves.easeInOut;

  /// The brand typeface (MASTER.md → "Tipografía"). Declared in `pubspec.yaml`
  /// as a single family with its five weights (400/500/600/700/800) so the
  /// engine picks the right `.ttf` from `fontWeight`.
  ///
  /// It replaces `GoogleFonts.plusJakartaSansTextTheme`, which stamped a
  /// one-weight family (`PlusJakartaSans_regular`) on every text style: asking
  /// for `w700`/`w800` through `copyWith` changed the requested weight but not
  /// the file that rendered, so every bold in the app came out at 400.
  static const String fontFamily = 'PlusJakartaSans';

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySoft,
      onPrimaryContainer: c.primaryOnSoft,
      secondary: c.primaryDeep,
      onSecondary: c.onPrimary,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.muted,
      onSurfaceVariant: c.textSecondary,
      error: c.expense,
      onError: c.onPrimary,
      outline: c.border,
      outlineVariant: c.border,
      scrim: c.scrim,
    );

    final textTheme = _textTheme(ThemeData(brightness: brightness).textTheme)
        .apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: fontFamily,
      textTheme: textTheme,
      dividerColor: c.border,
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      extensions: <ThemeExtension<dynamic>>[c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        modalBarrierColor: c.scrim,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(sheetRadius)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          // Height only. `Size.fromHeight` leaves the width at
          // `double.infinity`, i.e. an infinite *minimum* width: every button
          // in the app would be full-width by theme and no outer constraint
          // could shrink it. Full width is a layout decision, so screens that
          // need it ask for it (`SizedBox(width: double.infinity)`,
          // `Expanded`). 52pt tall and 20pt of side padding come from
          // `Button/Primary` in billetudo.pen.
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.surface,
          foregroundColor: c.textPrimary,
          // Same rule as the filled button above: impose the height, never the
          // width. Mirrors `Button/Secondary` in billetudo.pen.
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: c.border),
          // 700, same as the filled button: `Button/Secondary` (`kAVHJ`) sets
          // its label to 15/700 in billetudo.pen, not a lighter 600.
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: c.expense),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.background),
        actionTextColor: c.snackbarAction,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(0),
      ),
    );
  }

  /// Restamps every style of [base] onto the brand family at the design
  /// system's baseline weight.
  ///
  /// Material's own scale mixes `w400` and `w500`, but MASTER.md's weight
  /// palette starts at 500 (`500` body/metadata, `600` emphasis, `700` titles,
  /// `800` hero amounts) — 400 is not part of it. So any text that does not
  /// ask for a weight must land on 500, the frames' body weight, instead of
  /// inheriting Material's 400.
  ///
  /// Call sites raise it from there with `copyWith(fontWeight: ...)`, which
  /// now really swaps the font file (see [fontFamily]).
  static TextTheme _textTheme(TextTheme base) {
    TextStyle? brand(TextStyle? style) => style?.copyWith(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        );

    return TextTheme(
      displayLarge: brand(base.displayLarge),
      displayMedium: brand(base.displayMedium),
      displaySmall: brand(base.displaySmall),
      headlineLarge: brand(base.headlineLarge),
      headlineMedium: brand(base.headlineMedium),
      headlineSmall: brand(base.headlineSmall),
      titleLarge: brand(base.titleLarge),
      titleMedium: brand(base.titleMedium),
      titleSmall: brand(base.titleSmall),
      bodyLarge: brand(base.bodyLarge),
      bodyMedium: brand(base.bodyMedium),
      bodySmall: brand(base.bodySmall),
      labelLarge: brand(base.labelLarge),
      labelMedium: brand(base.labelMedium),
      labelSmall: brand(base.labelSmall),
    );
  }
}
