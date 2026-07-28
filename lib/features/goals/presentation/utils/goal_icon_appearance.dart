import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Resolves a goal's `icon` — a plain string in the domain, so it never
/// depends on Flutter — into the concrete [IconData] the card, the ring
/// label and the icon picker need. Same precedent as `CategoryAppearance`.
abstract final class GoalIconAppearance {
  const GoalIconAppearance._();

  /// Fallback for an empty/unrecognized icon name.
  static const IconData defaultIcon = LucideIcons.target;

  static const Map<String, IconData> _icons = {
    'target': LucideIcons.target,
    'shield': LucideIcons.shield,
    'palm-tree': LucideIcons.palmtree,
    'umbrella': LucideIcons.umbrella,
    'plane': LucideIcons.plane,
    'car': LucideIcons.car,
    'house': LucideIcons.house,
    'graduation-cap': LucideIcons.graduationCap,
    'gift': LucideIcons.gift,
    'heart': LucideIcons.heart,
    'piggy-bank': LucideIcons.piggyBank,
    'laptop': LucideIcons.laptop,
    'bike': LucideIcons.bike,
    'camera': LucideIcons.camera,
    'briefcase': LucideIcons.briefcase,
    'sparkles': LucideIcons.sparkles,
  };

  /// The set offered by the icon picker (`cwj6B`), in display order.
  static const List<String> iconNames = [
    'target',
    'shield',
    'palm-tree',
    'umbrella',
    'plane',
    'car',
    'house',
    'graduation-cap',
    'gift',
    'heart',
    'piggy-bank',
    'laptop',
    'bike',
    'camera',
    'briefcase',
    'sparkles',
  ];

  static IconData iconFor(String? name) =>
      _icons[name] ?? defaultIcon;
}
