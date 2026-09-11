import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction.dart';

/// Everything that survives the parsing of one bank notification: the fields a
/// rule explicitly identified, and nothing else.
///
/// **Zero retention (HU-03).** There is no field here — and there must never be
/// one — holding the notification text, whole or truncated. [merchantRaw] is
/// only the fragment a rule matched as the merchant; [ruleId] is what makes a
/// broken parser debuggable without keeping the message.
///
/// **[merchantRaw] can be a third party's name, and it syncs.** For a transfer
/// the counterparty is a person (`DANIELA TORO VALENCIA` from Nu), sometimes
/// masked by the issuer (`Aur*** Cri*******`). It is stored exactly as it
/// arrived — never completed, never unmasked — because it is the field that
/// makes the capture useful and it is the same thing the user would have typed
/// in the note by hand. But it is third-party PII that reaches Supabase
/// through `PendingCaptures`/`Transactions`, so the transparency screen
/// (HU-08) and the privacy policy have to declare it explicitly.
class ParsedNotification extends Equatable {
  const ParsedNotification({
    required this.issuerId,
    required this.sourcePackage,
    required this.ruleId,
    required this.amountMinor,
    required this.currency,
    required this.entryType,
    required this.postedAt,
    this.merchantRaw,
    this.accountHint,
    this.cardNetwork,
  });

  /// Catalog id of the issuer (`nu`, `nequi`, `google_wallet`, ...).
  final String issuerId;

  /// Android package that emitted the notification. Also the primary key of
  /// the issuer -> account binding (see [IssuerAccountBinding]).
  final String sourcePackage;

  /// The rule that produced this capture, stored on `PendingCaptures`.
  final String ruleId;

  /// Positive integer of minor units. Never a double, never negative.
  final int amountMinor;

  /// Explicit currency when the notification carried one (Wallet writes
  /// `38.000,00 COP`), the issuer's default otherwise.
  final String currency;

  /// `expense` unless a rule proved otherwise — ambiguity resolves to expense,
  /// the dominant case, and the user corrects it when dispatching.
  final TransactionType entryType;

  /// When the movement happened, per the notification's own timestamp.
  final DateTime postedAt;

  /// Merchant or counterparty, exactly as extracted. See the class doc.
  final String? merchantRaw;

  /// Last 4 digits of the card, when the issuer sends them. Only Wallet
  /// (`Visa ••5615`) and, presumably, Bancolombia do; Nu and Nequi never do,
  /// so account suggestion cannot depend on this field alone.
  final String? accountHint;

  /// Card network (`Visa`, `Mastercard`). A hint, NOT a merchant: it is kept
  /// out of [merchantRaw] on purpose. Not persisted in `PendingCaptures`
  /// today — there is no column for it.
  final String? cardNetwork;

  /// The pieces the suggested note may be composed of: only fields a rule
  /// identified, never leftovers of the message (HU-03). Presentation joins
  /// them and adds any localized label (`tarjeta`), which is why no Spanish
  /// word is baked in here.
  List<String> get noteParts => <String>[
        if (merchantRaw != null && merchantRaw!.isNotEmpty) merchantRaw!,
        if (accountHint != null && accountHint!.isNotEmpty) '*$accountHint',
      ];

  /// Convenience join of [noteParts]. Empty when nothing was identified — in
  /// which case the note stays empty, it is NOT filled with the message.
  String get suggestedNote => noteParts.join(' · ');

  /// Whether two captures may be presented as ONE proposed movement (HU-07).
  ///
  /// Same amount, same currency and a very short window — and, the hard rule:
  /// **never group opposite entry types.** Moving money from the user's own Nu
  /// to their own Nequi fires two simultaneous notifications of the same
  /// amount, one expense (Nu: `Enviaste $1,00`) and one income (Nequi: `Te
  /// enviaron $1`). Those are two real movements in two different accounts;
  /// merging them would erase one of them. The wallet+bank case that DOES
  /// group (Wallet and the issuing bank of the same card) is two expenses.
  ///
  /// Grouping is a presentation decision only: it never confirms, never
  /// discards and never merges by itself.
  bool canGroupWith(ParsedNotification other,
      {Duration window = const Duration(minutes: 3)}) {
    if (entryType != other.entryType) {
      return false;
    }
    if (amountMinor != other.amountMinor || currency != other.currency) {
      return false;
    }
    return postedAt.difference(other.postedAt).abs() <= window;
  }

  @override
  List<Object?> get props => <Object?>[
        issuerId,
        sourcePackage,
        ruleId,
        amountMinor,
        currency,
        entryType,
        postedAt,
        merchantRaw,
        accountHint,
        cardNetwork,
      ];
}

/// Binds an issuer's app to one of the user's accounts.
///
/// Why it exists: Nu and Nequi send NO card digits, so [ParsedNotification]
/// .accountHint is empty for them and last-4 matching cannot suggest an
/// account. The issuer itself is the reliable signal instead — a Nequi
/// notification is a movement of the user's Nequi account, and it works from
/// the very first capture.
///
/// Resolution order when suggesting an account: [ParsedNotification.accountHint]
/// first when it exists (it identifies the actual card, so it is more precise
/// than the issuer), this binding otherwise.
class IssuerAccountBinding extends Equatable {
  const IssuerAccountBinding({
    required this.packageName,
    required this.accountId,
  });

  final String packageName;
  final String accountId;

  @override
  List<Object?> get props => <Object?>[packageName, accountId];
}
