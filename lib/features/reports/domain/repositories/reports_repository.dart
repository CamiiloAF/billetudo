import '../../../../core/error/result.dart';
import '../entities/cashflow_series.dart';
import '../entities/category_breakdown.dart';
import '../entities/date_range.dart';
import '../entities/net_worth_series.dart';

/// Contract the Gráficas e informes feature depends on. Implemented in
/// `data/` over Drift (source of truth); every aggregate is computed in SQL
/// (see `docs/requirements/10-graficas-informes.md` → "Reglas de conteo" →
/// Fechas y agregación), never by iterating raw transactions in Dart.
///
/// `range` is an explicit parameter everywhere (HU-01, "Costura para Nivel
/// 1/2"): the caller passes the *requested* window; the implementation
/// resolves it against the earliest data available (`resolveEffectiveDateRange`)
/// and reports the result via `ChartHistoryBounds` on each series.
abstract class ReportsRepository {
  /// HU-01: income/expense/net per bucket. [includeDebtMovements] mirrors the
  /// "movimientos de deuda" toggle (default `true` = integrated).
  Stream<Result<CashflowSeries>> watchCashflow({
    required DateRange range,
    required bool includeDebtMovements,
  });

  /// HU-02: líquido vs. total, reconstructed at each point in time.
  /// [includeArchivedAccounts] mirrors the "incluir cuentas archivadas"
  /// toggle (default `false`).
  Stream<Result<NetWorthSeries>> watchNetWorth({
    required DateRange range,
    required bool includeArchivedAccounts,
  });

  /// HU-03: gasto agrupado por categoría raíz (+ "Sin categoría"), with each
  /// root's subcategories nested for the expand action. No rango limit.
  Stream<Result<CategoryBreakdown>> watchCategoryBreakdown({
    required DateRange range,
  });

  /// The earliest `date` among alive, in-scope transactions — the input
  /// `resolveEffectiveDateRange` clamps against for HU-06 "historial
  /// insuficiente". `null` when there is no data yet.
  Stream<Result<DateTime?>> watchEarliestDataDate();
}
