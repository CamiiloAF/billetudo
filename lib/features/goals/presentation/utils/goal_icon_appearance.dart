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
    'flag': LucideIcons.flag,
  };

  /// The set offered by the icon picker (`cwj6B`, "set expresivo"), in the
  /// exact 5x3 grid order the frame lays out. Confirmed against the real
  /// `.pen` tiles (not the row/tile *names*, which are stale copy-paste
  /// labels in Pencil — the tiles' own `icon` field is the source of truth).
  static const List<String> iconNames = [
    'plane',
    'umbrella',
    'shield',
    'gift',
    'laptop',
    'bike',
    'graduation-cap',
    'palm-tree',
    'house',
    'car',
    'heart',
    'target',
    'sparkles',
    'flag',
    'piggy-bank',
  ];

  static IconData iconFor(String? name) =>
      _icons[name] ?? defaultIcon;
}
