import 'package:equatable/equatable.dart';

/// The estimated result of paying a debt off with a fixed installment at a
/// fixed rate (HU-06, Fase 0 opcional). Everything here is labelled "estimado"
/// at presentation: day-count conventions and rounding never match a bank to
/// the cent.
class DebtPayoffProjection extends Equatable {
  const DebtPayoffProjection({
    required this.installmentCount,
    required this.payoffDate,
    required this.totalInterestMinor,
    required this.totalPaidMinor,
  });

  /// How many installments it takes to reach a zero balance.
  final int installmentCount;

  /// The estimated date the last installment lands on.
  final DateTime payoffDate;

  /// The sum of interest accrued along the way, in cents.
  final int totalInterestMinor;

  /// The sum actually paid (principal + interest), in cents. The final
  /// installment is trimmed to the remaining balance, so this is not simply
  /// `installmentCount × installment`.
  final int totalPaidMinor;

  @override
  List<Object?> get props => [
        installmentCount,
        payoffDate,
        totalInterestMinor,
        totalPaidMinor,
      ];
}
