package com.billetudo.app.capture

import android.content.Context
import android.content.SharedPreferences

/**
 * The handful of settings the notification service needs while no Flutter
 * engine is alive. Flutter writes them through the method channel; the service
 * only reads them.
 *
 * `SharedPreferences` and not Drift on purpose: the service runs in a process
 * where opening the PowerSync-managed database is neither possible nor
 * desirable.
 */
class CaptureSettings(context: Context) {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /**
     * Issuer ids the user switched on (HU-02).
     *
     * **Empty by default, and that default is load-bearing**: granting the
     * system permission alone must capture nothing. Never seed this with the
     * whole catalog.
     */
    fun enabledIssuers(): Set<String> =
        prefs.getStringSet(KEY_ENABLED_ISSUERS, emptySet()) ?: emptySet()

    fun isIssuerEnabled(issuerId: String): Boolean = enabledIssuers().contains(issuerId)

    /**
     * Replaces the enabled set. Read on every notification, so switching an
     * issuer off stops its captures immediately, without touching the system
     * permission.
     */
    fun setEnabledIssuers(issuerIds: Set<String>) {
        prefs.edit().putStringSet(KEY_ENABLED_ISSUERS, issuerIds).apply()
    }

    internal fun preferences(): SharedPreferences = prefs

    companion object {
        private const val PREFS_NAME = "billetudo_capture"
        private const val KEY_ENABLED_ISSUERS = "enabled_issuers"
    }
}
