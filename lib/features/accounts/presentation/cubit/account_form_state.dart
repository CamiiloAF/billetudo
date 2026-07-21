import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/account.dart';

enum AccountFormStatus {
  /// Reading the account being edited. A new account skips straight to [ready].
  loading,
  ready,
  saving,

  /// Persisted: the page pops.
  saved,
  failure,
}

/// State of the add/edit form (`CwiKu`/`xdLeB`/`jg9DA`).
///
/// Amounts live here as **text**, exactly as typed: they only become integer
/// cents when the form is submitted, through `MoneyFormatter`. Nothing here is
/// ever a `double`.
class AccountFormState extends Equatable {
  const AccountFormState({
    this.status = AccountFormStatus.loading,
    this.id,
    this.type,
    this.name = '',
    this.institution = '',
    this.currency = defaultCurrency,
    this.initialBalanceText = '',
    this.interestRateText = '',
    this.creditLimitText = '',
    this.statementDay,
    this.paymentDueDay,
    this.cardBalancePrimary,
    this.fullAccountNumber,
    this.numberReadFailed = false,
    this.last4 = '',
    this.typePickerExpanded = false,
    this.numberVisible = false,
    this.needsConfirmation = false,
    this.failure,
  });

  /// Field keys the form owns, for the ones the domain draft does not name.
  static const String fieldType = 'type';
  static const String fieldInitialBalance = 'initialBalanceMinor';

  static const String defaultCurrency = 'COP';

  /// The only currencies the picker offers today (design decision).
  static const List<String> supportedCurrencies = ['COP', 'USD'];

  final AccountFormStatus status;

  /// `null` while creating; the account id while editing.
  final String? id;

  /// `null` until the user picks one: a new account starts with a neutral grid.
  final AccountType? type;

  final String name;
  final String institution;
  final String currency;
  final String initialBalanceText;
  final String interestRateText;
  final String creditLimitText;
  final int? statementDay;
  final int? paymentDueDay;

  /// HU-04: which balance the card shows first. The form never edits it — the
  /// detail carousel does — but it is carried here so that saving an unrelated
  /// change round-trips the stored preference instead of resetting it: the
  /// update companion writes this field explicitly (HU-06), so a null would
  /// land as `debt`.
  final CardBalanceView? cardBalancePrimary;

  /// The number in the clear, on its way to (or freshly read from) secure
  /// storage — never Drift (HU-03). Prefilled when editing so the user sees
  /// what is stored and can change it.
  ///
  /// Empty means the field is empty, and nothing more: whether that is a
  /// deliberate delete depends on [numberReadFailed], which is why the two
  /// travel together.
  final String? fullAccountNumber;

  /// Secure storage refused to give the stored number back (a Keystore
  /// decryption failure, typically). The field is empty because it is
  /// *unknown*, not because there is nothing there — the form says so and the
  /// save leaves the stored number alone.
  final bool numberReadFailed;

  final String last4;
  final bool typePickerExpanded;

  /// Whether the number field shows its value. Ephemeral, like the detail's.
  final bool numberVisible;

  /// HU-06: the type/currency change needs the user to confirm it.
  final bool needsConfirmation;

  final Failure? failure;

  bool get isEditing => id != null;
  bool get isCard => type == AccountType.card;

  /// A new account shows the grid outright; editing collapses it into a pill
  /// until the user taps "Cambiar".
  bool get showTypeGrid => !isEditing || typePickerExpanded;

  /// Cash has no number, and a card only ever keeps its last 4 (HU-03).
  bool get showFullNumberField => type != null && type!.allowsFullAccountNumber;

  /// The manual last 4: offered when there is no full number to derive it from.
  bool get showLast4Field =>
      type != null &&
      type != AccountType.cash &&
      (!showFullNumberField || (fullAccountNumber ?? '').isEmpty);

  /// Every account type can carry a rate (HU-02): Pencil shows the field on
  /// the add form (`CwiKu`), on editing a card (`xdLeB`) and on the detail of
  /// a plain savings account (`ZCSCc`, "Tasa de interés: 3.5% anual") — the
  /// design never restricts it to cards. Cash is the one exception the
  /// mockups do not cover but that a real rate cannot apply to: physical cash
  /// does not accrue interest.
  bool get showInterestRateField => type != AccountType.cash;

  /// The stored number is unknown: the read failed and the user has not typed a
  /// replacement, so the empty field is hiding a value instead of stating there
  /// is none. Saving must leave the stored number alone, and the form must say
  /// why the field looks empty.
  bool get isNumberUnknown =>
      numberReadFailed && (fullAccountNumber ?? '').trim().isEmpty;

  /// The failing field, when the failure points at one.
  String? get failedField => failure is ValidationFailure
      ? (failure! as ValidationFailure).field
      : null;

  AccountFormState copyWith({
    AccountFormStatus? status,
    String? id,
    AccountType? type,
    String? name,
    String? institution,
    String? currency,
    String? initialBalanceText,
    String? interestRateText,
    String? creditLimitText,
    int? statementDay,
    int? paymentDueDay,
    CardBalanceView? cardBalancePrimary,
    String? fullAccountNumber,
    bool clearFullAccountNumber = false,
    bool? numberReadFailed,
    String? last4,
    bool? typePickerExpanded,
    bool? numberVisible,
    bool? needsConfirmation,
    Failure? failure,
  }) =>
      AccountFormState(
        status: status ?? this.status,
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        institution: institution ?? this.institution,
        currency: currency ?? this.currency,
        initialBalanceText: initialBalanceText ?? this.initialBalanceText,
        interestRateText: interestRateText ?? this.interestRateText,
        creditLimitText: creditLimitText ?? this.creditLimitText,
        statementDay: statementDay ?? this.statementDay,
        paymentDueDay: paymentDueDay ?? this.paymentDueDay,
        cardBalancePrimary: cardBalancePrimary ?? this.cardBalancePrimary,
        fullAccountNumber: clearFullAccountNumber
            ? null
            : fullAccountNumber ?? this.fullAccountNumber,
        numberReadFailed: numberReadFailed ?? this.numberReadFailed,
        last4: last4 ?? this.last4,
        typePickerExpanded: typePickerExpanded ?? this.typePickerExpanded,
        numberVisible: numberVisible ?? this.numberVisible,
        // Both are answers to the last submit: any later edit clears them
        // unless the caller says otherwise.
        needsConfirmation: needsConfirmation ?? false,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        id,
        type,
        name,
        institution,
        currency,
        initialBalanceText,
        interestRateText,
        creditLimitText,
        statementDay,
        paymentDueDay,
        cardBalancePrimary,
        fullAccountNumber,
        numberReadFailed,
        last4,
        typePickerExpanded,
        numberVisible,
        needsConfirmation,
        failure,
      ];
}
