import 'package:flutter/material.dart';

/// billetudo color tokens as a [ThemeExtension], an exact mirror of the
/// variables in `billetudo.pen` (see `design-system/billetudo/MASTER.md`).
///
/// Material's `ColorScheme` only covers a subset (primary, surface, error…);
/// our own semantic tokens (mint, sky, income, primarySoft…) live here. In a
/// widget:
///
///   final c = Theme.of(context).extension<AppColors>()!;
///   Container(color: c.mintSoft, child: Icon(..., color: c.mint));
///
/// **Never hardcode a hex in a screen** — always use a token.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryDeep,
    required this.primaryLight,
    required this.primarySoft,
    required this.primaryOnSoft,
    required this.primaryOnSoftStrong,
    required this.mint,
    required this.mintSoft,
    required this.sky,
    required this.skySoft,
    required this.peach,
    required this.peachSoft,
    required this.coral,
    required this.coralSoft,
    required this.amber,
    required this.amberSoft,
    required this.amberText,
    required this.teal,
    required this.tealSoft,
    required this.indigo,
    required this.indigoSoft,
    required this.background,
    required this.surface,
    required this.muted,
    required this.border,
    required this.skeleton,
    required this.textPrimary,
    required this.textSecondary,
    required this.onPrimary,
    required this.income,
    required this.incomeText,
    required this.expense,
    required this.expenseSoft,
    required this.expenseText,
    required this.snackbarAction,
    required this.scrim,
  });

  final Color primary;
  final Color primaryDeep;
  final Color primaryLight;
  final Color primarySoft;
  final Color primaryOnSoft;
  final Color primaryOnSoftStrong;
  final Color mint;
  final Color mintSoft;
  final Color sky;
  final Color skySoft;
  final Color peach;
  final Color peachSoft;
  final Color coral;
  final Color coralSoft;
  final Color amber;
  final Color amberSoft;

  /// `amber` calibrated for 12px/700 text on `$surface` (~5.12:1 in light;
  /// `amber` itself only clears ~4.2:1, failing AA). Same pattern as
  /// `expenseText`/`incomeText`. First real use: the "riesgo de sobregiro
  /// proyectado" caption/row of Presupuestos (HU-12), see
  /// `design-system/billetudo/pages/presupuestos.md`.
  final Color amberText;
  final Color teal;
  final Color tealSoft;
  final Color indigo;
  final Color indigoSoft;
  final Color background;
  final Color surface;
  final Color muted;
  final Color border;

  /// Placeholder fill for skeleton loaders only (never borders/dividers). In
  /// light it matches [border]; in dark it is deliberately lighter so the
  /// skeleton reads without shouting (MASTER.md).
  final Color skeleton;

  final Color textPrimary;
  final Color textSecondary;
  final Color onPrimary;
  final Color income;
  final Color incomeText;
  final Color expense;
  final Color expenseSoft;
  final Color expenseText;
  final Color snackbarAction;
  final Color scrim;

  /// Light theme — values from `billetudo.pen` (MASTER.md).
  static const AppColors light = AppColors(
    primary: Color(0xFF6C5CE7),
    primaryDeep: Color(0xFF5648C8),
    primaryLight: Color(0xFFA78BFA),
    primarySoft: Color(0xFFEEECFB),
    primaryOnSoft: Color(0xFF6C5CE7),
    primaryOnSoftStrong: Color(0xFF5648C8),
    mint: Color(0xFF059669),
    mintSoft: Color(0xFFE6F7EF),
    sky: Color(0xFF2563EB),
    skySoft: Color(0xFFE6F0FD),
    peach: Color(0xFFC2410C),
    peachSoft: Color(0xFFFDEEE6),
    coral: Color(0xFFE11D48),
    coralSoft: Color(0xFFFDE8ED),
    amber: Color(0xFF9B7608),
    amberSoft: Color(0xFFFDF3E0),
    amberText: Color(0xFF8A6906),
    teal: Color(0xFF0F766E),
    tealSoft: Color(0xFFE0F5F3),
    indigo: Color(0xFF3730A3),
    indigoSoft: Color(0xFFE7E6F7),
    background: Color(0xFFF4F3FA),
    surface: Color(0xFFFFFFFF),
    muted: Color(0xFFEEECFB),
    border: Color(0xFFECEBF3),
    skeleton: Color(0xFFECEBF3),
    textPrimary: Color(0xFF1C1B29),
    textSecondary: Color(0xFF6B6980),
    onPrimary: Color(0xFFFFFFFF),
    income: Color(0xFF22C55E),
    incomeText: Color(0xFF166534),
    expense: Color(0xFFDC2626),
    expenseSoft: Color(0xFFFDE8E8),
    expenseText: Color(0xFFB91C1C),
    snackbarAction: Color(0xFFA78BFA),
    scrim: Color(0x66000000),
  );

  /// Dark theme — values from `billetudo.pen` (MASTER.md).
  static const AppColors dark = AppColors(
    primary: Color(0xFF6D4FE0),
    primaryDeep: Color(0xFF5B4BE0),
    primaryLight: Color(0xFFA78BFA),
    primarySoft: Color(0xFF26243B),
    primaryOnSoft: Color(0xFFA78BFA),
    primaryOnSoftStrong: Color(0xFFA78BFA),
    mint: Color(0xFF34D399),
    mintSoft: Color(0xFF16321F),
    sky: Color(0xFF4C9AFF),
    skySoft: Color(0xFF1B2A42),
    peach: Color(0xFFFB923C),
    peachSoft: Color(0xFF3A2418),
    coral: Color(0xFFFB7185),
    coralSoft: Color(0xFF3A1620),
    amber: Color(0xFFFBDE24),
    amberSoft: Color(0xFF3A2E0F),
    amberText: Color(0xFFFBDE24),
    teal: Color(0xFF2DD4BF),
    tealSoft: Color(0xFF0F2E2B),
    indigo: Color(0xFF818CF8),
    indigoSoft: Color(0xFF211F45),
    background: Color(0xFF14141F),
    surface: Color(0xFF1E1E2E),
    muted: Color(0xFF26243B),
    border: Color(0xFF2A2A3D),
    skeleton: Color(0xFF45455F),
    textPrimary: Color(0xFFF4F3FA),
    textSecondary: Color(0xFF9A98B5),
    onPrimary: Color(0xFFFFFFFF),
    income: Color(0xFF34D399),
    incomeText: Color(0xFF34D399),
    expense: Color(0xFFDC2626),
    expenseSoft: Color(0xFF3A1616),
    expenseText: Color(0xFFF87171),
    snackbarAction: Color(0xFF5648C8),
    scrim: Color(0x66000000),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryDeep,
    Color? primaryLight,
    Color? primarySoft,
    Color? primaryOnSoft,
    Color? primaryOnSoftStrong,
    Color? mint,
    Color? mintSoft,
    Color? sky,
    Color? skySoft,
    Color? peach,
    Color? peachSoft,
    Color? coral,
    Color? coralSoft,
    Color? amber,
    Color? amberSoft,
    Color? amberText,
    Color? teal,
    Color? tealSoft,
    Color? indigo,
    Color? indigoSoft,
    Color? background,
    Color? surface,
    Color? muted,
    Color? border,
    Color? skeleton,
    Color? textPrimary,
    Color? textSecondary,
    Color? onPrimary,
    Color? income,
    Color? incomeText,
    Color? expense,
    Color? expenseSoft,
    Color? expenseText,
    Color? snackbarAction,
    Color? scrim,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primaryLight: primaryLight ?? this.primaryLight,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryOnSoft: primaryOnSoft ?? this.primaryOnSoft,
      primaryOnSoftStrong: primaryOnSoftStrong ?? this.primaryOnSoftStrong,
      mint: mint ?? this.mint,
      mintSoft: mintSoft ?? this.mintSoft,
      sky: sky ?? this.sky,
      skySoft: skySoft ?? this.skySoft,
      peach: peach ?? this.peach,
      peachSoft: peachSoft ?? this.peachSoft,
      coral: coral ?? this.coral,
      coralSoft: coralSoft ?? this.coralSoft,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      amberText: amberText ?? this.amberText,
      teal: teal ?? this.teal,
      tealSoft: tealSoft ?? this.tealSoft,
      indigo: indigo ?? this.indigo,
      indigoSoft: indigoSoft ?? this.indigoSoft,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      skeleton: skeleton ?? this.skeleton,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      onPrimary: onPrimary ?? this.onPrimary,
      income: income ?? this.income,
      incomeText: incomeText ?? this.incomeText,
      expense: expense ?? this.expense,
      expenseSoft: expenseSoft ?? this.expenseSoft,
      expenseText: expenseText ?? this.expenseText,
      snackbarAction: snackbarAction ?? this.snackbarAction,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryOnSoft: Color.lerp(primaryOnSoft, other.primaryOnSoft, t)!,
      primaryOnSoftStrong:
          Color.lerp(primaryOnSoftStrong, other.primaryOnSoftStrong, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      mintSoft: Color.lerp(mintSoft, other.mintSoft, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      skySoft: Color.lerp(skySoft, other.skySoft, t)!,
      peach: Color.lerp(peach, other.peach, t)!,
      peachSoft: Color.lerp(peachSoft, other.peachSoft, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      coralSoft: Color.lerp(coralSoft, other.coralSoft, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      amberText: Color.lerp(amberText, other.amberText, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      tealSoft: Color.lerp(tealSoft, other.tealSoft, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      indigoSoft: Color.lerp(indigoSoft, other.indigoSoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      skeleton: Color.lerp(skeleton, other.skeleton, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeText: Color.lerp(incomeText, other.incomeText, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
      expenseText: Color.lerp(expenseText, other.expenseText, t)!,
      snackbarAction: Color.lerp(snackbarAction, other.snackbarAction, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// Sugar for reading tokens: `context.colors.mint`.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
