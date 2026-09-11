import 'package:equatable/equatable.dart';

import '../../../accounts/domain/entities/account.dart';
import '../../../categories/domain/entities/category.dart';

/// Everything `ParseSpokenTransaction` needs, handed in by the caller.
///
/// The parser performs **no I/O**: the user's categories and accounts are
/// passed in already loaded, so the whole thing stays a pure
/// `text -> fields` function that tests can drive without a platform, a
/// database or a microphone (HU-10 of `17-captura-voz.md`).
class SpokenTransactionInput extends Equatable {
  const SpokenTransactionInput({
    required this.transcript,
    this.languageCode = 'es',
    this.currency = 'COP',
    this.categories = const <Category>[],
    this.accounts = const <Account>[],
  });

  /// The recognizer's transcription. Lives in memory only: nothing in this
  /// feature ever writes it to disk (HU-06, retención cero).
  final String transcript;

  /// The **app's** locale language code ('es' or 'en'), never the device's:
  /// the parser uses the same language the recognition was requested with and
  /// never tries to detect it from the text (HU-08).
  final String languageCode;

  /// Currency of the account the movement will land on. Only used to decide
  /// whether the magnitude-elision heuristic applies (see
  /// `SpokenAmountParser`); the parser never converts between currencies.
  final String currency;

  /// The user's categories, roots and subcategories alike. Their names take
  /// priority over the built-in synonym dictionary — it is the user's
  /// vocabulary, not ours (HU-04b).
  final List<Category> categories;

  /// The user's accounts. Archived ones are ignored by the matcher.
  final List<Account> accounts;

  @override
  List<Object?> get props => [
        transcript,
        languageCode,
        currency,
        categories,
        accounts,
      ];
}
