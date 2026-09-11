package com.billetudo.app.capture

/**
 * Turns the amount fragment a rule captured into an integer of minor units
 * (cents). Money is NEVER a floating point number in this project.
 *
 * Mirror of `lib/features/capture/domain/parsing/notification_amount_parser.dart`;
 * both must accept the three real formats seen so far:
 *
 * - `$58.470,00` (Nu)                  -> 5847000
 * - `$1`         (Nequi)               -> 100
 * - `38.000,00 COP` (Google Wallet)    -> 3800000
 * - `128.920,00` (Nu, no `$` at all)   -> 12892000
 *
 * The mistake this guards against is a factor of 1000: in es-CO `128.920,00`
 * is one hundred twenty-eight thousand pesos. The separator is decided by
 * inspection rather than by a fixed locale, because issuers are inconsistent.
 */
object NotificationAmountParser {

    /**
     * @return the POSITIVE amount in cents, or null when there is no usable
     * figure. Null means NO CAPTURE: an amount-less capture saves the user no
     * work, it only adds noise to the inbox (HU-03).
     */
    fun parseMinor(raw: String): Int? {
        // Drop currency symbols, letters (`COP`), spaces and any other noise.
        var cleaned = raw.replace(Regex("[^0-9.,]"), "")
        // A trailing separator belongs to the sentence, not to the number
        // (`por $1.` -> `1`).
        cleaned = cleaned.replace(Regex("[.,]+$"), "")
        if (cleaned.isEmpty()) return null

        val lastDot = cleaned.lastIndexOf('.')
        val lastComma = cleaned.lastIndexOf(',')
        val lastSeparator = maxOf(lastDot, lastComma)

        var digits = cleaned
        var fraction = ""
        if (lastSeparator >= 0) {
            val separator = cleaned[lastSeparator]
            val tail = cleaned.substring(lastSeparator + 1)
            val bothPresent = lastDot >= 0 && lastComma >= 0
            val occurrences = cleaned.count { it == separator }
            // Decimal when both separator kinds coexist (the last one wins), or
            // when a single separator is not followed by a group of exactly
            // three digits. `45.900` is forty-five thousand nine hundred;
            // `45.90` is forty-five pesos ninety cents.
            val isDecimal = bothPresent || (occurrences == 1 && tail.length != 3)
            if (isDecimal) {
                digits = cleaned.substring(0, lastSeparator)
                fraction = tail
            }
        }

        val integerDigits = digits.replace(Regex("[.,]"), "")
        if (integerDigits.isEmpty()) return null
        val units = integerDigits.toLongOrNull() ?: return null

        val amountMinor = units * 100 + centsFromFraction(fraction)
        // Always positive: the sign is carried by the entry type, never by the
        // amount. Guard the Int boundary — a malformed run of digits must not
        // wrap around into a negative amount.
        if (amountMinor <= 0 || amountMinor > Int.MAX_VALUE) return null
        return amountMinor.toInt()
    }

    private fun centsFromFraction(fraction: String): Int {
        val onlyDigits = fraction.replace(Regex("[^0-9]"), "")
        if (onlyDigits.isEmpty()) return 0
        if (onlyDigits.length == 1) return onlyDigits.toInt() * 10
        val firstTwo = onlyDigits.substring(0, 2).toInt()
        if (onlyDigits.length == 2) return firstTwo
        // More than two decimals: round half up on the third digit.
        val third = onlyDigits.substring(2, 3).toInt()
        return if (third >= 5) firstTwo + 1 else firstTwo
    }
}
