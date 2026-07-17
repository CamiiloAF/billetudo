import 'package:equatable/equatable.dart';

/// One income transaction reduced to what the zero-based summary needs
/// (HU-06). Money is always minor units; currency is ISO-4217.
class PeriodIncome extends Equatable {
  const PeriodIncome({
    required this.amountMinor,
    required this.currency,
    required this.date,
  });

  final int amountMinor;
  final String currency;
  final DateTime date;

  @override
  List<Object?> get props => [amountMinor, currency, date];
}
