import 'package:equatable/equatable.dart';

/// A single snapshot of the patrimonio report (HU-02), reconstructed at
/// [date] — never read from a cached balance column.
class NetWorthPoint extends Equatable {
  const NetWorthPoint({
    required this.date,
    required this.liquidMinor,
    required this.totalMinor,
  });

  final DateTime date;

  /// Patrimonio líquido/disponible: Σ saldos de cuentas activas at [date].
  final int liquidMinor;

  /// Patrimonio total: [liquidMinor] − Σ pendiente `iOwe` + Σ pendiente
  /// `owedToMe`, both outstanding balances as of [date].
  final int totalMinor;

  @override
  List<Object?> get props => [date, liquidMinor, totalMinor];
}
