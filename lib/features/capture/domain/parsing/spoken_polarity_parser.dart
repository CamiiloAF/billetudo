import '../../../transactions/domain/entities/transaction.dart'
    show TransactionType;
import 'capture_lexicon.dart';
import 'spoken_tokens.dart';

/// Decides whether the dictated movement is an expense or an income, from the
/// verb (HU-01/HU-04).
///
/// **Transfers are out of scope by product decision**: detecting two accounts
/// in one sentence ("pasé cien mil de Bancolombia a Nequi") is the case that
/// gets it wrong most often, and a wrong transfer moves money between two real
/// balances. So this never returns `TransactionType.transfer`.
///
/// Income phrases are matched first: "me pagaron" contains "pagaron", and
/// reading that as "pagué" would register a two-million-peso salary as a
/// two-million-peso expense — the exact failure the requirement calls out as
/// worse than not understanding anything.
class SpokenPolarityParser {
  const SpokenPolarityParser();

  TransactionType? parse(SpokenTokens tokens, {required CaptureLexicon lexicon}) {
    for (final phrase in lexicon.incomeVerbs) {
      final index = tokens.indexOfSequence(phrase);
      if (index >= 0) {
        tokens.consume(index, index + phrase.length);
        return TransactionType.income;
      }
    }
    for (final phrase in lexicon.expenseVerbs) {
      final index = tokens.indexOfSequence(phrase);
      if (index >= 0) {
        tokens.consume(index, index + phrase.length);
        return TransactionType.expense;
      }
    }
    return null;
  }
}
