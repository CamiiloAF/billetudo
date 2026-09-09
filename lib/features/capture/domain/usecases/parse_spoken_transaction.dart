import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../transactions/domain/entities/transaction.dart'
    show TransactionType;
import '../entities/spoken_transaction_draft.dart';
import '../entities/spoken_transaction_input.dart';
import '../parsing/capture_lexicon.dart';
import '../parsing/spoken_account_matcher.dart';
import '../parsing/spoken_amount_parser.dart';
import '../parsing/spoken_category_matcher.dart';
import '../parsing/spoken_date_parser.dart';
import '../parsing/spoken_polarity_parser.dart';
import '../parsing/spoken_tokens.dart';

/// Turns one dictated phrase into a prefilled transaction draft (HU-04).
///
/// Pure domain, no I/O: text in, fields out. That is what lets the whole
/// example table of `17-captura-voz.md` be a unit test suite with no
/// microphone, no platform and no database (HU-10).
///
/// Extraction order matters and is not arbitrary:
///
/// 1. **date** — "hace **dos** días" and "el **5**" carry numbers that the
///    amount parser would otherwise swallow;
/// 2. **amount** — the only field whose absence makes the capture unusable;
/// 3. **account** — so an account name is never re-read as a category;
/// 4. **category** — user names first, dictionary second;
/// 5. **polarity** — the verb, which also gets it out of the note;
/// 6. **note** — literally whatever nobody claimed.
///
/// Nothing here is mandatory. A draft carrying only the amount is a partial
/// success, and even an empty one still opens the form (HU-05).
@injectable
class ParseSpokenTransaction {
  const ParseSpokenTransaction();

  static const SpokenDateParser _dateParser = SpokenDateParser();
  static const SpokenAmountParser _amountParser = SpokenAmountParser();
  static const SpokenAccountMatcher _accountMatcher = SpokenAccountMatcher();
  static const SpokenCategoryMatcher _categoryMatcher = SpokenCategoryMatcher();
  static const SpokenPolarityParser _polarityParser = SpokenPolarityParser();

  /// Longest note kept, so a rambling dictation cannot push an unbounded
  /// string into the form.
  static const int _maxNoteLength = 240;

  SpokenTransactionDraft call(SpokenTransactionInput input) {
    final tokens = SpokenTokens(input.transcript);
    final lexicon = lexiconFor(input.languageCode);

    final date = _dateParser.parse(tokens, lexicon: lexicon, now: clock.now());
    if (date != null) {
      tokens.consume(date.start, date.end);
    }

    final amount = _amountParser.parse(
      tokens,
      lexicon: lexicon,
      currency: input.currency,
    );
    if (amount != null) {
      tokens.consume(amount.start, amount.end);
    }

    final account = _accountMatcher.match(tokens, input.accounts);
    if (account != null) {
      tokens.consume(account.start, account.end);
    }

    // Polarity before the category so the category pass looks for the right
    // kind of category, and the verb is already out of the note.
    final type = _polarityParser.parse(tokens, lexicon: lexicon);
    final category = _categoryMatcher.match(
      tokens,
      categories: input.categories,
      lexicon: lexicon,
      // With no verb the form's own default (expense) decides which
      // categories are eligible — the parser does not invent a type.
      kind: type == TransactionType.income
          ? CategoryKind.income
          : CategoryKind.expense,
    );
    if (category != null) {
      tokens.consume(category.start, category.end);
    }

    return SpokenTransactionDraft(
      transcript: input.transcript,
      amountMinor: amount?.amountMinor,
      amountIsUncertain: amount?.isUncertain ?? false,
      type: type,
      categoryId: category?.category.id,
      categoryName: category?.category.name,
      categoryKind: category?.category.kind,
      accountId: account?.account.id,
      accountName: account?.account.name,
      date: date?.date,
      note: _note(tokens, lexicon),
    );
  }

  /// Whatever nobody claimed, minus the command muletillas and articles at
  /// the edges. Interior fillers stay: "seguro **del** carro" reads like a
  /// note, "seguro carro" reads like a bug.
  String? _note(SpokenTokens tokens, CaptureLexicon lexicon) {
    final words = tokens.freeWords
        .where((word) => word.isNotEmpty)
        .toList(growable: true);
    bool isFiller(String word) => lexicon.fillerWords.contains(
          _normalizedFiller(word),
        );
    while (words.isNotEmpty && isFiller(words.first)) {
      words.removeAt(0);
    }
    while (words.isNotEmpty && isFiller(words.last)) {
      words.removeLast();
    }
    if (words.isEmpty) {
      return null;
    }
    final note = words.join(' ');
    return note.length <= _maxNoteLength
        ? note
        : note.substring(0, _maxNoteLength).trimRight();
  }

  String _normalizedFiller(String word) => SpokenTokens(word).normalized.first;
}
