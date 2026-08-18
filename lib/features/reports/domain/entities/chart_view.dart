import 'package:equatable/equatable.dart';

import 'chart_tier.dart';

/// Identifies one of the report views declared in `ChartCatalog`. Mirrors the
/// 4 tabs of the Gráficas e informes screen (HU-01 to HU-04); a 5th id is
/// added only when a new view is actually built, never speculatively.
enum ChartViewId { dashboard, cashflow, netWorth, categoryBreakdown }

/// A single entry in the report catalog: which view it is and which tier
/// gates it. See "Costura para Nivel 1/2" in
/// `docs/requirements/fase-1/10-graficas-informes.md`. Every entry is `essential`
/// today — Fase 0 builds no `advanced` view.
class ChartView extends Equatable {
  const ChartView({required this.id, required this.tier});

  final ChartViewId id;
  final ChartTier tier;

  @override
  List<Object?> get props => [id, tier];
}
