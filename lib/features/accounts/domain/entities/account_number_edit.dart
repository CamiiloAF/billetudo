import 'package:equatable/equatable.dart';

/// What a draft asks to happen to the full account number held in the device's
/// secure storage (HU-03).
///
/// These three cases used to collapse into one nullable `String`, where `null`
/// meant both "this account has no number" and "erase the stored one". A failed
/// Keystore read produced that very same `null`, so saving an unrelated edit
/// (a rename) wiped the number — and since HU-03 keeps it off the cloud on
/// purpose, there is no copy to restore it from and nothing tells the user.
///
/// Hence [KeepAccountNumber], and hence the default: a draft that says nothing
/// about the number must never be the reason it disappears.
sealed class AccountNumberEdit extends Equatable {
  const AccountNumberEdit();

  @override
  List<Object?> get props => const [];
}

/// Store [value], replacing whatever the account had.
final class SetAccountNumber extends AccountNumberEdit {
  const SetAccountNumber(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

/// Erase the stored number: the user emptied the field on purpose, or the new
/// type does not admit one (cash, card).
final class ClearAccountNumber extends AccountNumberEdit {
  const ClearAccountNumber();
}

/// Leave the stored number exactly as it is, because this draft does not know
/// it: reading it from secure storage failed. Writing anything — including a
/// delete — would destroy a value nobody was able to read back.
final class KeepAccountNumber extends AccountNumberEdit {
  const KeepAccountNumber();
}
