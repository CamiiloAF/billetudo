import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';

/// The "Supusimos $20.000 por «veinte»" pill of the amount `Zona Fija`
/// (`bwaHq` in `Va8F7`).
///
/// It exists because the parser's magnitude-elision heuristic multiplies a
/// bare number by a thousand — in Colombia "gasté veinte" means 20.000 — and
/// without a visible mark someone can save $500.000 believing they confirmed
/// $500.
///
/// Three deliberate choices, all recorded on the component itself:
///
/// - **Never `$expense`.** This is a reading worth checking, not an error and
///   not money lost; red would make a helpful guess look like a failure. It
///   lives in the `$primary-soft` / `$hint-text` family.
/// - **`info`, not `mic`.** The "Dictar" pill sits ~60px away in the same
///   zone with the same `$primary-soft` fill, so repeating its glyph would
///   read as a second button. The absent stroke is the other distinguishing
///   signal.
/// - **It quotes the user.** The dictated words are the whole justification;
///   an amount that changed with no explanation is worse than no mark at all.
///
/// It is transitory: `TransactionFormState.amountIsUncertain` drops on the
/// first key that edits the amount and the zone goes back to `E1vEe7`'s
/// layout, which is why the 36px it costs the scrollable zone is acceptable.
class TransactionAmountAssumptionHint extends StatelessWidget {
  const TransactionAmountAssumptionHint({
    required this.amountMinor,
    required this.currency,
    required this.spokenText,
    super.key,
  });

  final int amountMinor;
  final String currency;

  /// The dictated words the amount was inferred from, verbatim.
  final String spokenText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // Keeps the 14pt glyph optically centred on the first line
                // when the label wraps to a second one.
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  LucideIcons.info,
                  size: 14,
                  color: colors.hintText,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.captureVoiceAmountAssumption(
                    money.formatSymbol(amountMinor, currencyCode: currency),
                    spokenText,
                  ),
                  // Two lines, never an ellipsis: truncating would cut the
                  // figure or the quote, which are the only two things this
                  // pill exists to show. Pencil does not render wrapping here
                  // because the mockup's string is short; real dictations are
                  // not guaranteed to be.
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: colors.hintText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
