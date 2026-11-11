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

    /**
     * Epoch milliseconds of the last capture this service actually produced
     * (HU-09), or `null` when nothing was captured on this device yet.
     *
     * It is the raw timestamp, never a message: Flutter uses it to tell
     * "configured but nothing arrived in 3 days" from "it used to arrive and
     * stopped", which is all the degraded state needs. No notification content
     * is involved, so storing it does not weaken the zero-retention promise.
     */
    fun lastCaptureAt(): Long? =
        if (prefs.contains(KEY_LAST_CAPTURE_AT)) {
            prefs.getLong(KEY_LAST_CAPTURE_AT, 0L)
        } else {
            null
        }

    /**
     * Records that a notification made it through [IssuerFilter] and the rule
     * engine and became a capture.
     *
     * `commit` and not `apply`, for the same reason `PendingCaptureBuffer`
     * commits its queue: the system can kill this process moments after
     * handling a notification, and an unflushed timestamp would leave HU-09
     * thinking nothing ever arrived.
     */
    fun markCaptureReceived(epochMs: Long) {
        if (epochMs <= 0L) return
        // Monotonic on purpose. Android re-delivers still-active notifications
        // when the listener reconnects, carrying the original `postTime`; an
        // unconditional write would move `lastCaptureAt` backwards and make
        // HU-09 report a stale "última captura" (or believe a fresh one is
        // old). Only a newer capture may advance the timestamp.
        val previous = lastCaptureAt() ?: 0L
        if (epochMs <= previous) return
        prefs.edit().putLong(KEY_LAST_CAPTURE_AT, epochMs).commit()
    }

    /**
     * Epoch milliseconds of the last time the system bound the notification
     * listener, or `null` when it never got to bind on this device (HU-09).
     *
     * [lastCaptureAt] only proves the listener worked *and* a bank notified. A
     * manufacturer that rejects the bind (MIUI/HyperOS logs
     * `AutStart Unable to bind notification listener service`) leaves it `null`
     * forever, so the app would stay silent for its three-day heuristic while
     * the user believes capture is on. This timestamp is the direct signal: it
     * is written by `onListenerConnected`, before any notification exists.
     */
    fun lastListenerConnectedAt(): Long? =
        if (prefs.contains(KEY_LAST_LISTENER_CONNECTED_AT)) {
            prefs.getLong(KEY_LAST_LISTENER_CONNECTED_AT, 0L)
        } else {
            null
        }

    /**
     * Records that the system bound the listener to this process.
     *
     * `commit` and not `apply`, like [markCaptureReceived]: the process can be
     * killed moments after binding, and this write is the only durable proof
     * that the listener ever reached the system. Unlike a capture it is
     * overwritten on every connection on purpose: "the last time it connected"
     * is exactly what HU-09 compares against its six-hour window.
     */
    fun markListenerConnected(epochMs: Long) {
        prefs.edit().putLong(KEY_LAST_LISTENER_CONNECTED_AT, epochMs).commit()
    }

    internal fun preferences(): SharedPreferences = prefs

    companion object {
        private const val PREFS_NAME = "billetudo_capture"
        private const val KEY_ENABLED_ISSUERS = "enabled_issuers"
        private const val KEY_LAST_CAPTURE_AT = "last_capture_at_epoch_ms"
        private const val KEY_LAST_LISTENER_CONNECTED_AT =
            "last_listener_connected_at_epoch_ms"
    }
}
