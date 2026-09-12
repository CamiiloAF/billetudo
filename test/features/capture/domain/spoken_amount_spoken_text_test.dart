import 'package:billetudo/features/capture/domain/entities/spoken_transaction_input.dart';
import 'package:billetudo/features/capture/domain/usecases/parse_spoken_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

/// The words behind an assumed amount.
///
/// The "Supusimos $20.000 por «veinte»" pill is only honest if the quote is
/// what the person actually said, so the parser has to carry the original
/// words — not the normalized ones it matched on.
void main() {
  const parse = ParseSpokenTransaction();

  SpokenTransactionInput input(String transcript) => SpokenTransactionInput(
        transcript: transcript,
        languageCode: 'es',
        currency: 'COP',
      );

  test('a guessed amount carries the words it was guessed from', () {
    final draft = parse(input('gasté veinte en almuerzo'));

    expect(draft.amountMinor, 2000000);
    expect(draft.amountIsUncertain, isTrue);
    expect(draft.amountSpokenText, 'veinte');
  });

  test('a bare number word below the threshold is quoted whole', () {
    final draft = parse(input('gasté quinientos en el bus'));

    expect(draft.amountIsUncertain, isTrue);
    expect(draft.amountSpokenText, 'quinientos');
  });

  test(
      'a run carrying a scale word is never a guess, so it is never quoted — '
      "`Va8F7`'s note cites “mil quinientos” as the widest case the pill has "
      'to fit, but that phrase states its own scale and the parser does not '
      'assume anything about it', () {
    final draft = parse(input('gasté mil quinientos en el bus'));

    expect(draft.amountMinor, 150000);
    expect(draft.amountIsUncertain, isFalse);
    expect(draft.amountSpokenText, isNull);
  });

  test('the quote is the raw transcription, accents and casing included', () {
    // The parser matches on a normalized form; the pill must not show that
    // form back to the user.
    final draft = parse(input('gasté Veinte en almuerzo'));

    expect(draft.amountSpokenText, 'Veinte');
  });

  test('an explicit amount carries no quote, because nothing was assumed', () {
    final draft = parse(input('gasté veinte mil en almuerzo'));

    expect(draft.amountMinor, 2000000);
    expect(draft.amountIsUncertain, isFalse);
    expect(draft.amountSpokenText, isNull);
  });

  test('no amount at all means no quote either', () {
    final draft = parse(input('almuerzo con Ana'));

    expect(draft.amountMinor, isNull);
    expect(draft.amountSpokenText, isNull);
  });
}
