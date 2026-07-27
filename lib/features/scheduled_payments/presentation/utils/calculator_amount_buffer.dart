import '../../../../core/utils/money_formatter.dart';
import '../../../transactions/presentation/cubit/transaction_form_state.dart'
    show CalcOperator;

/// A local, presentation-only port of the Transacciones anchored keypad's
/// arithmetic (`TransactionFormCubit`'s `amount*Pressed` methods): digit
/// entry, a pending binary operator and `=` evaluation, all on integer minor
/// units so money never becomes a `double`.
///
/// Kept out of a cubit on purpose: the confirmation sheet's amount field only
/// needs the *math*, not `TransactionFormCubit`'s much larger form state (or
/// a dependency on the Transactions feature's presentation layer beyond this
/// one enum). `NumericKeypad` itself — the visual widget — is reused as-is.
class CalculatorAmountBuffer {
  const CalculatorAmountBuffer({
    this.amountMinor = 0,
    this.calcOperator,
    this.calcOperand,
    this.entryFractionDigits = -1,
    this.startNewOperand = false,
    this.justEvaluated = false,
  });

  final int amountMinor;
  final CalcOperator? calcOperator;
  final int? calcOperand;
  final int entryFractionDigits;
  final bool startNewOperand;
  final bool justEvaluated;

  static const int _maxAmountMinor = 999999999999;

  CalculatorAmountBuffer _copyWith({
    int? amountMinor,
    CalcOperator? calcOperator,
    int? calcOperand,
    int? entryFractionDigits,
    bool? startNewOperand,
    bool? justEvaluated,
    bool clearCalc = false,
  }) =>
      CalculatorAmountBuffer(
        amountMinor: amountMinor ?? this.amountMinor,
        calcOperator: clearCalc ? null : (calcOperator ?? this.calcOperator),
        calcOperand: clearCalc ? null : (calcOperand ?? this.calcOperand),
        entryFractionDigits: entryFractionDigits ?? this.entryFractionDigits,
        startNewOperand: startNewOperand ?? this.startNewOperand,
        justEvaluated: justEvaluated ?? this.justEvaluated,
      );

  CalculatorAmountBuffer digitPressed(int digit, {required String currency}) {
    if (digit < 0 || digit > 9) {
      return this;
    }
    final base = _startFreshOperandIfNeeded();
    final decimals = MoneyFormatter.inputDecimals(currency);

    final int next;
    final int nextFraction;
    if (base.entryFractionDigits < 0) {
      final whole = base.amountMinor ~/ 100;
      next = (whole * 10 + digit) * 100;
      nextFraction = -1;
    } else if (base.entryFractionDigits < decimals) {
      final place = _pow10(1 - base.entryFractionDigits);
      next = base.amountMinor + digit * place;
      nextFraction = base.entryFractionDigits + 1;
    } else {
      return base; // Fraction already full for this currency; ignore.
    }
    if (next > _maxAmountMinor) {
      return base;
    }
    return base._copyWith(amountMinor: next, entryFractionDigits: nextFraction);
  }

  CalculatorAmountBuffer decimalPressed({required String currency}) {
    if (MoneyFormatter.inputDecimals(currency) == 0) {
      return this;
    }
    final base = _startFreshOperandIfNeeded();
    if (base.entryFractionDigits >= 0) {
      return base;
    }
    return base._copyWith(entryFractionDigits: 0);
  }

  CalculatorAmountBuffer operatorPressed(CalcOperator operator) {
    if (startNewOperand && calcOperator != null) {
      return _copyWith(calcOperator: operator);
    }
    final left = calcOperator != null && calcOperand != null
        ? _evaluate(calcOperand!, calcOperator!, amountMinor)
        : amountMinor;
    return _copyWith(
      amountMinor: left,
      calcOperand: left,
      calcOperator: operator,
      startNewOperand: true,
      justEvaluated: false,
      entryFractionDigits: -1,
    );
  }

  CalculatorAmountBuffer equalsPressed() {
    final operator = calcOperator;
    final operand = calcOperand;
    if (operator == null || operand == null) {
      return this;
    }
    final result = _evaluate(operand, operator, amountMinor);
    return _copyWith(
      amountMinor: result,
      justEvaluated: true,
      startNewOperand: false,
      entryFractionDigits: -1,
      clearCalc: true,
    );
  }

  /// Clears the whole amount at once (long-press on backspace, item 5),
  /// mirroring `TransactionFormCubit.amountCleared`: back to 0 with no pending
  /// operator, operand or fraction.
  CalculatorAmountBuffer cleared() => const CalculatorAmountBuffer();

  CalculatorAmountBuffer backspacePressed() {
    var base = this;
    if (base.justEvaluated) {
      base = base._copyWith(justEvaluated: false, clearCalc: true);
    }
    if (base.startNewOperand) {
      return base._copyWith(
        amountMinor: 0,
        startNewOperand: false,
        entryFractionDigits: -1,
      );
    }
    if (base.entryFractionDigits > 0) {
      final place = _pow10(2 - base.entryFractionDigits);
      final digit = (base.amountMinor ~/ place) % 10;
      return base._copyWith(
        amountMinor: base.amountMinor - digit * place,
        entryFractionDigits: base.entryFractionDigits - 1,
      );
    }
    if (base.entryFractionDigits == 0) {
      return base._copyWith(entryFractionDigits: -1);
    }
    final whole = base.amountMinor ~/ 100;
    return base._copyWith(amountMinor: (whole ~/ 10) * 100);
  }

  CalculatorAmountBuffer _startFreshOperandIfNeeded() {
    if (justEvaluated) {
      return _copyWith(
        amountMinor: 0,
        entryFractionDigits: -1,
        justEvaluated: false,
        clearCalc: true,
      );
    }
    if (startNewOperand) {
      return _copyWith(
        amountMinor: 0,
        entryFractionDigits: -1,
        startNewOperand: false,
      );
    }
    return this;
  }

  static int _evaluate(int left, CalcOperator operator, int right) {
    final int raw;
    switch (operator) {
      case CalcOperator.add:
        raw = left + right;
      case CalcOperator.subtract:
        raw = left - right;
      case CalcOperator.multiply:
        raw = ((BigInt.from(left) * BigInt.from(right) + BigInt.from(50)) ~/
                BigInt.from(100))
            .toInt();
      case CalcOperator.divide:
        if (right == 0) {
          return left;
        }
        raw = ((BigInt.from(left) * BigInt.from(100) +
                    BigInt.from(right) ~/ BigInt.two) ~/
                BigInt.from(right))
            .toInt();
    }
    if (raw < 0) {
      return 0;
    }
    return raw > _maxAmountMinor ? _maxAmountMinor : raw;
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
