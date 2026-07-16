import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Resolves a category's `icon`/`color` — plain strings in the domain, so it
/// never depends on Flutter — into the concrete [IconData]/[Color] the icon
/// picker (`lAxmS`) and every row/avatar need.
///
/// Icon names follow the lucide naming used by `billetudo.pen`
/// (`default_categories_seed.dart` is the other place that names them); this
/// is the single place that maps them to the real Lucide icon, so no widget
/// hardcodes an `IconData` for a category.
abstract final class CategoryAppearance {
  const CategoryAppearance._();

  /// The picker's grid (`lAxmS`): 32 lucide icons grouped by affinity (food,
  /// transport, home, health, ...), in the order they render.
  static const List<String> iconNames = [
    'utensils',
    'bus',
    'car',
    'home',
    'shirt',
    'heart-pulse',
    'shield',
    'credit-card',
    'graduation-cap',
    'gift',
    'party-popper',
    'plane',
    'dumbbell',
    'book-open',
    'paw-print',
    'baby',
    'wrench',
    'phone',
    'wifi',
    'piggy-bank',
    'coffee',
    'banknote',
    'briefcase',
    'building-2',
    'landmark',
    'trending-up',
    'refresh-cw',
    'rotate-ccw',
    'send',
    'users',
    'file-text',
    'ellipsis',
  ];

  /// The 7 decorative palette tokens (`mint`/`sky`/`peach`/`coral`/`amber`/
  /// `teal`/`indigo`) — never `primary`, reserved for brand/CTAs.
  static const List<String> colorTokens = [
    'mint',
    'sky',
    'peach',
    'coral',
    'amber',
    'teal',
    'indigo',
  ];

  /// Fallback icon shown before the user picks one (`sparkles`, neutral),
  /// per the "crear categoría" empty state.
  static const String defaultIconName = 'sparkles';

  static const Map<String, IconData> _icons = {
    'utensils': LucideIcons.utensils,
    'bus': LucideIcons.bus,
    'car': LucideIcons.car,
    'home': LucideIcons.home,
    'shirt': LucideIcons.shirt,
    'heart-pulse': LucideIcons.heartPulse,
    'shield': LucideIcons.shield,
    'credit-card': LucideIcons.creditCard,
    'graduation-cap': LucideIcons.graduationCap,
    'gift': LucideIcons.gift,
    'party-popper': LucideIcons.partyPopper,
    'plane': LucideIcons.plane,
    'dumbbell': LucideIcons.dumbbell,
    'book-open': LucideIcons.bookOpen,
    'paw-print': LucideIcons.pawPrint,
    'baby': LucideIcons.baby,
    'wrench': LucideIcons.wrench,
    'phone': LucideIcons.smartphone,
    'wifi': LucideIcons.wifi,
    'piggy-bank': LucideIcons.piggyBank,
    'coffee': LucideIcons.coffee,
    'banknote': LucideIcons.banknote,
    'briefcase': LucideIcons.briefcase,
    'building-2': LucideIcons.building2,
    'landmark': LucideIcons.landmark,
    'trending-up': LucideIcons.trendingUp,
    'refresh-cw': LucideIcons.refreshCw,
    'rotate-ccw': LucideIcons.rotateCcw,
    'send': LucideIcons.send,
    'users': LucideIcons.users,
    'file-text': LucideIcons.fileText,
    'ellipsis': LucideIcons.ellipsis,
    defaultIconName: LucideIcons.sparkles,
  };

  /// The icon for [name], falling back to the neutral default when [name] is
  /// `null` or unknown (e.g. an icon removed from the catalog after being
  /// saved on an old category).
  static IconData iconFor(String? name) =>
      _icons[name] ?? _icons[defaultIconName]!;

  /// The strong tone of [token] (e.g. the icon itself), falling back to
  /// [AppColors.textSecondary] when [token] is `null`/unknown — neutral, same
  /// treatment as an unpicked appearance.
  static Color colorFor(AppColors colors, String? token) => switch (token) {
        'mint' => colors.mint,
        'sky' => colors.sky,
        'peach' => colors.peach,
        'coral' => colors.coral,
        'amber' => colors.amber,
        'teal' => colors.teal,
        'indigo' => colors.indigo,
        _ => colors.textSecondary,
      };

  /// The soft/background tone of [token], falling back to [AppColors.muted].
  static Color softColorFor(AppColors colors, String? token) => switch (token) {
        'mint' => colors.mintSoft,
        'sky' => colors.skySoft,
        'peach' => colors.peachSoft,
        'coral' => colors.coralSoft,
        'amber' => colors.amberSoft,
        'teal' => colors.tealSoft,
        'indigo' => colors.indigoSoft,
        _ => colors.muted,
      };
}
