import 'package:billetudo/features/reports/domain/entities/chart_tier.dart';
import 'package:billetudo/features/reports/domain/entities/chart_view.dart';
import 'package:billetudo/features/reports/domain/services/chart_access_guard.dart';
import 'package:billetudo/features/reports/domain/services/chart_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Costura para Nivel 1/2": Fase 0 has no `advanced` entry, so the guard
/// must always grant access — no Nivel 0 view can ever be gated.
void main() {
  const guard = ChartAccessGuard();

  test('every view in the catalog is essential today', () {
    expect(
      ChartCatalog.views.every((view) => view.tier == ChartTier.essential),
      isTrue,
    );
  });

  test('grants access to every catalog entry', () {
    for (final view in ChartCatalog.views) {
      expect(guard.canAccess(view), isTrue);
    }
  });

  test('canAccessView resolves by id through the catalog', () {
    expect(guard.canAccessView(ChartViewId.dashboard), isTrue);
    expect(guard.canAccessView(ChartViewId.cashflow), isTrue);
    expect(guard.canAccessView(ChartViewId.netWorth), isTrue);
    expect(guard.canAccessView(ChartViewId.categoryBreakdown), isTrue);
  });
}
