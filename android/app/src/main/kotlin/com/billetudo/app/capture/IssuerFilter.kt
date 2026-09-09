package com.billetudo.app.capture

/**
 * THE most sensitive class of the app. Read it slowly; no automated reviewer
 * in this repository covers Kotlin.
 *
 * `NotificationListenerService` receives EVERY notification of the device.
 * On the very device this feature was built for, the shade also holds
 * WhatsApp ("Copia de seguridad en curso"), LinkedIn, and an SMS carrying a
 * one-time security code (`87210 JUAN, has ingresado una clave inc...`).
 * Reading any of that — even to decide it is uninteresting, even into a local
 * variable, even into a log line — is exactly what the app promises it does
 * not do (HU-08, `docs/requirements/fase-2/19-notificaciones-bancarias.md`).
 *
 * So the filter is a GATE, not a predicate applied afterwards: it answers with
 * the issuer using only `packageName`, and the caller may not touch
 * `Notification.extras` until it has an issuer in hand. Two conditions, both
 * required:
 *
 *  1. the package belongs to a CATALOGUED issuer (closed catalog, shipped in
 *     `issuer_rules.json`), and
 *  2. the user has switched that issuer ON (off by default; a granted system
 *     permission with no issuer enabled captures nothing).
 *
 * If either fails the notification is dropped: not parsed, not stored, not
 * counted, not logged.
 */
class IssuerFilter(
    private val ruleSet: IssuerRuleSet,
    private val settings: CaptureSettings,
) {
    /**
     * @param packageName the ONLY field of the notification that may be read
     * before this call returns.
     * @return the issuer allowed to be parsed, or null to drop the
     * notification without reading anything else.
     */
    fun resolveEnabledIssuer(packageName: String?): IssuerDefinition? {
        if (packageName.isNullOrEmpty()) return null
        val issuer = ruleSet.issuerForPackage(packageName) ?: return null
        if (!settings.isIssuerEnabled(issuer.issuerId)) return null
        return issuer
    }
}
