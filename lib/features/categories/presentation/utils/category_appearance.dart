import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/category_icon_catalog.dart';

/// Resolves a category's `icon`/`color` — plain strings in the domain, so it
/// never depends on Flutter — into the concrete [IconData]/[Color] the icon
/// picker (`lAxmS`) and every row/avatar need.
///
/// Icon names follow the lucide naming used by `billetudo.pen` (the
/// `category_seeds` catalog in Supabase is the other place that names them —
/// see `docs/requirements/05-auth-sync.md`, decision #12); this is the single
/// place that maps them to the real Lucide icon, so no widget hardcodes an
/// `IconData` for a category.
abstract final class CategoryAppearance {
  const CategoryAppearance._();

  /// The picker's grid (`lAxmS`): 64 lucide icons grouped by affinity (food,
  /// transport, home, health, ...), in the order they render. The names
  /// themselves live in `domain/` ([CategoryIconCatalog.names]) since they
  /// don't depend on Flutter; this just re-exports that single source of
  /// truth for presentation callers.
  static const List<String> iconNames = CategoryIconCatalog.names;

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

  /// Fallback icon for a saved-but-unknown icon name.
  static const String defaultIconName = 'sparkles';

  /// Shown where nothing has been picked *yet* (an empty appearance slot).
  ///
  /// Deliberately NOT [defaultIconName]: `sparkles` is the AI/nudge glyph of
  /// the system (it labels the assistant entry points and the envelope-mode
  /// nudge strip), so using it as a placeholder promises an AI suggestion
  /// where there is only "pick an icon". `shapes` is a neutral
  /// "choose a symbol" affordance and belongs to no semantic family.
  static const IconData placeholderIcon = LucideIcons.shapes;

  static const Map<String, IconData> _icons = {
    'utensils-crossed': LucideIcons.utensilsCrossed,
    'bus': LucideIcons.bus,
    'car': LucideIcons.car,
    'house': LucideIcons.house,
    'heart-pulse': LucideIcons.heartPulse,
    'shield-check': LucideIcons.shieldCheck,
    'repeat': LucideIcons.repeat,
    'shopping-bag': LucideIcons.shoppingBag,
    'party-popper': LucideIcons.partyPopper,
    'graduation-cap': LucideIcons.graduationCap,
    'paw-print': LucideIcons.pawPrint,
    'credit-card': LucideIcons.creditCard,
    'landmark': LucideIcons.landmark,
    'file-text': LucideIcons.fileText,
    'send': LucideIcons.send,
    'gift': LucideIcons.gift,
    'wallet': LucideIcons.wallet,
    'laptop': LucideIcons.laptop,
    'briefcase': LucideIcons.briefcase,
    'inbox': LucideIcons.inbox,
    'trending-up': LucideIcons.trendingUp,
    'hand-coins': LucideIcons.handCoins,
    'rotate-ccw': LucideIcons.rotateCcw,
    'heart-handshake': LucideIcons.heartHandshake,
    'shopping-cart': LucideIcons.shoppingCart,
    'coffee': LucideIcons.coffee,
    'fuel': LucideIcons.fuel,
    'wrench': LucideIcons.wrench,
    'zap': LucideIcons.zap,
    'wifi': LucideIcons.wifi,
    'tv': LucideIcons.tv,
    'washing-machine': LucideIcons.washingMachine,
    'cat': LucideIcons.cat,
    'dog': LucideIcons.dog,
    'music': LucideIcons.music,
    'gamepad-2': LucideIcons.gamepad2,
    'clapperboard': LucideIcons.clapperboard,
    'headphones': LucideIcons.headphones,
    'trophy': LucideIcons.trophy,
    'bike': LucideIcons.bike,
    'pill': LucideIcons.pill,
    'stethoscope': LucideIcons.stethoscope,
    'hammer': LucideIcons.hammer,
    'droplet': LucideIcons.droplet,
    'flame': LucideIcons.flame,
    'monitor': LucideIcons.monitor,
    'smartphone': LucideIcons.smartphone,
    'piggy-bank': LucideIcons.piggyBank,
    'coins': LucideIcons.coins,
    'receipt': LucideIcons.receipt,
    'calculator': LucideIcons.calculator,
    'scale': LucideIcons.scale,
    'scissors': LucideIcons.scissors,
    'plane': LucideIcons.plane,
    'luggage': LucideIcons.luggage,
    'map-pin': LucideIcons.mapPin,
    'bed': LucideIcons.bed,
    'train': LucideIcons.train,
    'users': LucideIcons.users,
    'baby': LucideIcons.baby,
    'book-open': LucideIcons.bookOpen,
    'building-2': LucideIcons.building2,
    'church': LucideIcons.church,
    'dumbbell': LucideIcons.dumbbell,
    defaultIconName: LucideIcons.sparkles,
  };

  /// The icon for [name], falling back to the neutral default when [name] is
  /// `null` or unknown (e.g. an icon removed from the catalog after being
  /// saved on an old category).
  static IconData iconFor(String? name) =>
      _icons[name] ?? _icons[defaultIconName]!;

  /// Icon for an appearance slot that may be deliberately empty: the neutral
  /// [placeholderIcon] when nothing was picked (`name == null`), the real glyph
  /// otherwise. Unlike [iconFor], a null name reads as "nothing picked" and
  /// shows the placeholder — so the value displayed after saving matches the
  /// one shown in the form — instead of falling back to the `sparkles` default
  /// (which is reserved for a saved-but-unknown name).
  static IconData iconForOrPlaceholder(String? name) =>
      name == null ? placeholderIcon : iconFor(name);

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
