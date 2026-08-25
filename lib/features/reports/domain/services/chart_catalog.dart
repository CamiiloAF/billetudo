import '../entities/chart_tier.dart';
import '../entities/chart_view.dart';

/// The declarative catalog of every report view (see "Costura para Nivel
/// 1/2" in `docs/requirements/fase-1/10-graficas-informes.md`). Fase 0 declares the
/// 4 essential views of `docs/requirements/fase-1/10-graficas-informes.md`; a Fase 4
/// `advanced` view is added here as a plain new entry, never by branching on
/// a flag scattered across the codebase.
abstract final class ChartCatalog {
  static const List<ChartView> views = [
    ChartView(id: ChartViewId.dashboard, tier: ChartTier.essential),
    ChartView(id: ChartViewId.cashflow, tier: ChartTier.essential),
    ChartView(id: ChartViewId.netWorth, tier: ChartTier.essential),
    ChartView(id: ChartViewId.categoryBreakdown, tier: ChartTier.essential),
  ];

  static ChartView byId(ChartViewId id) =>
      views.firstWhere((view) => view.id == id);
}
