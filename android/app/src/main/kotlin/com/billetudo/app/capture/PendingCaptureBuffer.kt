package com.billetudo.app.capture

import org.json.JSONArray
import org.json.JSONObject

/**
 * Hand-off queue between the notification service and Flutter.
 *
 * **Why it exists:** `NotificationListenerService` wakes up with the app
 * closed and no Flutter engine alive, so it cannot write to Drift. Captures
 * are parked here until the app opens and drains them into `PendingCaptures`.
 *
 * **What it holds:** ONLY fields a rule identified — amount, merchant, last 4,
 * type, timestamp, rule id, package. Never the notification text, not even
 * "until the app opens": persisting it until then is still persisting it, and
 * that is precisely what zero retention forbids (HU-03).
 *
 * **Bounded on purpose:** at most [MAX_ENTRIES]. A user who does not open the
 * app for weeks drops the OLDEST captures rather than growing an unbounded
 * blob of financial data on disk. Losing an old candidate costs the user one
 * manual entry; keeping every one of them forever costs privacy.
 */
class PendingCaptureBuffer(private val settings: CaptureSettings) {

    /** Appends one capture, evicting the oldest entries beyond the cap. */
    @Synchronized
    fun add(capture: ParsedCapture) {
        val array = readArray()
        array.put(capture.toJson())
        val trimmed = if (array.length() > MAX_ENTRIES) {
            // Drop from the FRONT: the oldest go first.
            JSONArray().apply {
                for (i in (array.length() - MAX_ENTRIES) until array.length()) {
                    put(array.get(i))
                }
            }
        } else {
            array
        }
        write(trimmed)
    }

    /**
     * Returns every buffered capture AND clears the buffer, atomically with
     * respect to [add]. Called once by Flutter on start/resume: a capture can
     * neither be read twice nor be lost between two calls.
     */
    @Synchronized
    fun drain(): List<Map<String, Any?>> {
        val array = readArray()
        val drained = mutableListOf<Map<String, Any?>>()
        for (i in 0 until array.length()) {
            val entry = array.optJSONObject(i) ?: continue
            drained += entry.toMap()
        }
        write(JSONArray())
        return drained
    }

    /** Drops everything without handing it over (used by "delete my data"). */
    @Synchronized
    fun clear() {
        write(JSONArray())
    }

    private fun readArray(): JSONArray {
        val raw = settings.preferences().getString(KEY_BUFFER, null) ?: return JSONArray()
        return runCatching { JSONArray(raw) }.getOrElse { JSONArray() }
    }

    private fun write(array: JSONArray) {
        // `commit`, not `apply`: the service can be killed by the system
        // moments after handling a notification, and an unflushed capture is a
        // capture the user never gets.
        settings.preferences().edit().putString(KEY_BUFFER, array.toString()).commit()
    }

    private fun ParsedCapture.toJson(): JSONObject = JSONObject().apply {
        put("issuerId", issuerId)
        put("packageName", packageName)
        put("ruleId", ruleId)
        put("amountMinor", amountMinor)
        put("currency", currency)
        put("entryType", entryType)
        put("postedAtEpochMs", postedAtEpochMs)
        put("merchantRaw", merchant ?: JSONObject.NULL)
        put("accountHint", accountHint ?: JSONObject.NULL)
        put("cardNetwork", cardNetwork ?: JSONObject.NULL)
    }

    private fun JSONObject.toMap(): Map<String, Any?> = mapOf(
        "issuerId" to optString("issuerId"),
        "packageName" to optString("packageName"),
        "ruleId" to optString("ruleId"),
        "amountMinor" to optInt("amountMinor"),
        "currency" to optString("currency"),
        "entryType" to optString("entryType"),
        "postedAtEpochMs" to optLong("postedAtEpochMs"),
        "merchantRaw" to optStringOrNull("merchantRaw"),
        "accountHint" to optStringOrNull("accountHint"),
        "cardNetwork" to optStringOrNull("cardNetwork"),
    )

    private fun JSONObject.optStringOrNull(key: String): String? =
        if (isNull(key)) null else optString(key).ifEmpty { null }

    companion object {
        private const val KEY_BUFFER = "pending_captures"

        /** ~200 entries: months of real usage, still a bounded footprint. */
        const val MAX_ENTRIES = 200
    }
}
