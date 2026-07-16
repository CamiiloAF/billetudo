import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Resolves a category's `icon`/`color` — plain strings in the domain, so it
/// never depends on Flutter — into the concrete [IconData]/[Color] the icon
/// picker (`lAxmS`) and every row/avatar need.
///
/// Icon names follow the lucide naming used by `billetudo.pen`
/// (`default_categories_seed.dart` is the other place that names them); this
/// is the single place that maps them to a Material equivalent, so no widget
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
    'utensils': Icons.restaurant_outlined,
    'bus': Icons.directions_bus_outlined,
    'car': Icons.directions_car_outlined,
    'home': Icons.home_outlined,
    'shirt': Icons.checkroom_outlined,
    'heart-pulse': Icons.monitor_heart_outlined,
    'shield': Icons.shield_outlined,
    'credit-card': Icons.credit_card_outlined,
    'graduation-cap': Icons.school_outlined,
    'gift': Icons.card_giftcard_outlined,
    'party-popper': Icons.celebration_outlined,
    'plane': Icons.flight_outlined,
    'dumbbell': Icons.fitness_center_outlined,
    'book-open': Icons.menu_book_outlined,
    'paw-print': Icons.pets_outlined,
    'baby': Icons.child_care_outlined,
    'wrench': Icons.build_outlined,
    'phone': Icons.smartphone_outlined,
    'wifi': Icons.wifi,
    'piggy-bank': Icons.savings_outlined,
    'coffee': Icons.local_cafe_outlined,
    'banknote': Icons.attach_money,
    'briefcase': Icons.work_outline,
    'building-2': Icons.apartment_outlined,
    'landmark': Icons.account_balance_outlined,
    'trending-up': Icons.trending_up,
    'refresh-cw': Icons.autorenew,
    'rotate-ccw': Icons.replay,
    'send': Icons.send_outlined,
    'users': Icons.people_outline,
    'file-text': Icons.description_outlined,
    'ellipsis': Icons.more_horiz,
    defaultIconName: Icons.auto_awesome_outlined,
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
