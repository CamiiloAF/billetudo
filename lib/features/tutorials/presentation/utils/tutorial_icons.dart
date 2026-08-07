import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Maps a `TutorialContent.iconName` (a lucide icon name, e.g. `'wallet'`) to
/// its concrete [IconData] — same split as `CategoryIconCatalog` /
/// `CategoryAppearance.iconFor`: `domain/` never imports `IconData`, so this
/// small lookup lives in `presentation/`.
abstract final class TutorialIcons {
  const TutorialIcons._();

  static const Map<String, IconData> _icons = {
    'wallet': LucideIcons.wallet,
    'target': LucideIcons.target,
    'landmark': LucideIcons.landmark,
    'calendar-clock': LucideIcons.calendarClock,
    'link': LucideIcons.link,
    'hand-coins': LucideIcons.handCoins,
    'arrow-left-right': LucideIcons.arrowLeftRight,
  };

  /// Falls back to a generic `info` glyph for a name this catalog does not
  /// (yet) know, rather than throwing — a tutorial's icon is decorative, not
  /// load-bearing.
  static IconData iconFor(String name) => _icons[name] ?? LucideIcons.info;
}
