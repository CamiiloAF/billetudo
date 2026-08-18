import 'package:injectable/injectable.dart';

import '../entities/chart_tier.dart';
import '../entities/chart_view.dart';
import 'chart_catalog.dart';

/// The single point of guard for opening a report view (see "Costura para
/// Nivel 1/2" in `docs/requirements/fase-1/10-graficas-informes.md`).
///
/// Fase 0: every entry in `ChartCatalog` is `essential`, so this always
/// grants access — there is no quota to check yet. Fase 4 connects the
/// server-side quota/AdMob-SSV/RevenueCat check here for `advanced` entries,
/// without touching any view.
@lazySingleton
class ChartAccessGuard {
  const ChartAccessGuard();

  /// Whether [view] may be opened right now. Fase 0: always `true` — no
  /// `advanced` view exists yet, and Nivel 0 must never be gated (CLAUDE.md).
  bool canAccess(ChartView view) => switch (view.tier) {
        ChartTier.essential => true,
        ChartTier.advanced => true,
      };

  /// Convenience overload keyed by id, so callers do not need to resolve the
  /// catalog entry themselves.
  bool canAccessView(ChartViewId id) => canAccess(ChartCatalog.byId(id));
}
