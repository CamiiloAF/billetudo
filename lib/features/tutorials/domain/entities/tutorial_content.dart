import 'package:equatable/equatable.dart';

import 'tutorial_key.dart';

/// One bullet point of a tutorial sheet: a short heading plus its
/// explanatory body. Both are already-localized strings — this entity never
/// resolves `AppLocalizations` itself, the presentation layer does, so it
/// stays free of any Flutter/l10n dependency.
class TutorialPoint extends Equatable {
  const TutorialPoint({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  List<Object?> get props => [heading, body];
}

/// Content of a single tutorial sheet — the one shared widget
/// (`core/widgets/tutorial_sheet.dart`) is parameterized by this, never by a
/// feature-specific widget.
///
/// Pure entity: no Drift, no Supabase, no Flutter `IconData` (the icon is a
/// lucide icon name, same pattern as `CategoryIconCatalog`) — presentation
/// maps a name to a concrete icon.
class TutorialContent extends Equatable {
  const TutorialContent({
    required this.key,
    required this.title,
    required this.points,
    required this.iconName,
    this.ctaLabel,
  });

  /// Which of the 12 tutorials this content is for — drives "seen" tracking.
  final TutorialKey key;

  final String title;

  /// 2-3 points for a HU-01 screen tutorial, 1-2 for a HU-02 sub-flow one
  /// (convention from `docs/requirements/fase-1/16-minitutoriales.md`, not enforced
  /// at runtime — `List.length` cannot be checked in a const assert without
  /// giving up `const` construction, and every caller of this entity is the
  /// presentation-layer content map, not arbitrary user input).
  final List<TutorialPoint> points;

  /// Lucide icon name from the design system (e.g. `'wallet'`), never a
  /// literal Flutter `IconData` in `domain/`.
  final String iconName;

  /// Label of the primary CTA that navigates to the real create action
  /// (HU-01 only, e.g. "Crear mi primer presupuesto"). `null` means this
  /// sheet has no navigation CTA — only "Entendido" — which is always the
  /// case for HU-02 sub-flow tutorials ([TutorialKey.isScreenTutorial] is
  /// `false`) and MUST be `null` there.
  final String? ctaLabel;

  /// Whether this sheet shows the HU-01 primary CTA (`ctaLabel` is set) in
  /// addition to "Entendido".
  bool get hasNavigationCta => ctaLabel != null;

  @override
  List<Object?> get props => [key, title, points, iconName, ctaLabel];
}
