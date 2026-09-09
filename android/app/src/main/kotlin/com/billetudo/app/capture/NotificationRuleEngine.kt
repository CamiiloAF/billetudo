package com.billetudo.app.capture

/**
 * A capture candidate: the fields a rule identified, and nothing else.
 *
 * There is NO field here holding the notification text, whole or truncated,
 * and none may ever be added (zero retention, HU-03). [ruleId] is what makes a
 * misfiring parser debuggable without keeping the message.
 *
 * [merchant] may be a third party's name (`DANIELA TORO VALENCIA`), sometimes
 * masked by the issuer (`Aur*** Cri*******`). It is stored exactly as it
 * arrived — never completed, never unmasked — and it does sync to the backend
 * through `PendingCaptures`, which is why the transparency screen has to
 * declare it.
 */
data class ParsedCapture(
    val issuerId: String,
    val packageName: String,
    val ruleId: String,
    /** Positive integer of cents. Never a floating point number. */
    val amountMinor: Int,
    val currency: String,
    /** `income` / `expense`; `expense` whenever the rules were ambiguous. */
    val entryType: String,
    val postedAtEpochMs: Long,
    val merchant: String?,
    /** Card last 4 when the issuer sends them (Wallet does, Nu/Nequi do not). */
    val accountHint: String?,
    /** `Visa`, `Mastercard`... A hint, deliberately NOT part of [merchant]. */
    val cardNetwork: String?,
)

/**
 * The production parsing engine. Runs inside the notification service, with no
 * Flutter engine alive.
 *
 * Its Dart mirror is
 * `lib/features/capture/domain/usecases/parse_bank_notification.dart` and both
 * read the same `issuer_rules.json`. Keep them behaviourally identical: the
 * Dart test battery is the only automated proof this logic works, so a
 * divergence here is a silent regression.
 */
class NotificationRuleEngine(private val ruleSet: IssuerRuleSet) {

    /**
     * @param issuer already resolved by [IssuerFilter]; this function is never
     * called for a package that was not catalogued AND enabled.
     * @param packageName the emitting package, stored as-is: an issuer may
     * ship under more than one package and the capture records the real one.
     * @param title `EXTRA_TITLE`.
     * @param text `EXTRA_BIG_TEXT` if present, `EXTRA_TEXT` otherwise (the
     * collapsed row the user sees is truncated with an ellipsis; the extras
     * are not).
     * @return the candidate, or null when the notification must not produce
     * one: an ignore rule matched (OTP, promo, security notice, statement,
     * payment reminder), no rule matched, or the matched rule yielded no
     * usable amount.
     */
    fun parse(
        issuer: IssuerDefinition,
        packageName: String,
        title: String,
        text: String,
        postedAtEpochMs: Long,
    ): ParsedCapture? {
        val combined = "$title\n$text"

        // Global ignores first by priority: an OTP that happens to contain a
        // figure must never be read as a movement.
        val rules = (ruleSet.globalIgnoreRules + issuer.rules)
            .sortedByDescending { it.priority }

        for (rule in rules) {
            val surface = when (rule.target) {
                RuleTarget.TITLE -> title
                RuleTarget.TEXT -> text
                RuleTarget.COMBINED -> combined
            }
            val match = rule.regex.find(surface) ?: continue
            if (rule.action == RuleAction.IGNORE) return null

            val amountRaw = rule.captures["amount"]?.let { rule.regex.group(match, it) }
                ?: return null
            // No amount, no capture. Do NOT fall through to a lower-priority
            // rule: reading the same message twice is how a wrong amount gets
            // invented.
            val amountMinor = NotificationAmountParser.parseMinor(amountRaw) ?: return null

            return ParsedCapture(
                issuerId = issuer.issuerId,
                packageName = packageName,
                ruleId = rule.ruleId,
                amountMinor = amountMinor,
                currency = capture(rule, match, "currency")?.uppercase()
                    ?: issuer.defaultCurrency,
                // Ambiguity resolves to expense, the dominant case; the user
                // corrects it when dispatching the capture.
                entryType = rule.entryType ?: "expense",
                postedAtEpochMs = postedAtEpochMs,
                merchant = capture(rule, match, "merchant"),
                accountHint = normalizeLast4(capture(rule, match, "last4")),
                cardNetwork = capture(rule, match, "cardNetwork"),
            )
        }

        // Nothing matched. The content is dropped; only an anonymous counter
        // per issuer may ever be kept, never the text (HU-03).
        return null
    }

    private fun capture(rule: IssuerRule, match: MatchResult, field: String): String? {
        val groupName = rule.captures[field] ?: return null
        return rule.regex.group(match, groupName)?.trim()?.ifEmpty { null }
    }

    /**
     * Normalizes whatever masking the issuer used (`••5615`, `*5615`,
     * `**** 5615`, `x5615`, `...5615`) down to the four digits.
     */
    private fun normalizeLast4(raw: String?): String? {
        val digits = raw?.replace(Regex("[^0-9]"), "") ?: return null
        if (digits.length < 4) return null
        return digits.substring(digits.length - 4)
    }
}
