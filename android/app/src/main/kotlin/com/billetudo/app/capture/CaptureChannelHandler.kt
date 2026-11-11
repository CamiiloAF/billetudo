package com.billetudo.app.capture

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The only door between Flutter and the capture service.
 *
 * Mirrors `lib/features/capture/data/datasources/capture_method_channel_datasource.dart`;
 * the method names and payload keys are a contract between the two files.
 *
 * Note what this channel does NOT expose: there is no way to ask it for the
 * content of a notification, because no such content is kept anywhere.
 */
class CaptureChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    private val settings = CaptureSettings(context)
    private val buffer = PendingCaptureBuffer(settings)
    private val systemSettings = CaptureSystemSettings(context)

    fun register(messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, CHANNEL)
        channel.setMethodCallHandler(this)
        // Kept so the listener can push `onCaptureBuffered` while this engine
        // is alive. Cleared when the engine is destroyed (MainActivity).
        eventsChannel = channel
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isPermissionGranted" -> result.success(isNotificationAccessGranted())
            "openPermissionSettings" -> {
                openNotificationAccessSettings()
                result.success(null)
            }
            "getEnabledIssuers" -> result.success(settings.enabledIssuers().toList())
            "setEnabledIssuers" -> {
                val ids = call.argument<List<String>>("issuerIds").orEmpty().toSet()
                settings.setEnabledIssuers(ids)
                result.success(null)
            }
            "drainPendingCaptures" -> {
                val captures = buffer.drain()
                result.success(captures)
            }
            "getInstalledIssuerApps" -> result.success(installedIssuerApps())
            "clearPendingCaptures" -> {
                buffer.clear()
                result.success(null)
            }
            // HU-09: the phone-side facts behind "is capture still alive".
            // Read on demand, never cached: the user or the system can change
            // any of them between two visits to Avisos.
            "getDiagnostics" -> result.success(
                mapOf(
                    "lastCaptureAtEpochMs" to settings.lastCaptureAt(),
                    // The direct signals (HU-09): the durable proof that the
                    // system bound this listener at some point, and whether it
                    // is bound in this process right now. A null timestamp plus
                    // `false` is the MIUI/HyperOS rejected-bind case.
                    "lastListenerConnectedAtEpochMs" to
                        settings.lastListenerConnectedAt(),
                    "listenerConnectedNow" to
                        BilletudoNotificationListenerService.isConnected,
                    "batteryOptimizationExempt" to
                        systemSettings.isIgnoringBatteryOptimizations(),
                    "manufacturer" to systemSettings.manufacturer(),
                    "autostartAvailable" to systemSettings.autostartAvailable(),
                ),
            )
            "requestIgnoreBatteryOptimizations" -> {
                if (systemSettings.requestIgnoreBatteryOptimizations()) {
                    result.success(null)
                } else {
                    result.error(
                        ERROR_NO_ACTIVITY,
                        "No system screen accepted the battery request",
                        null,
                    )
                }
            }
            "openAutostartSettings" -> {
                if (systemSettings.openAutostartSettings()) {
                    result.success(null)
                } else {
                    result.error(
                        ERROR_NO_ACTIVITY,
                        "No system screen accepted the autostart request",
                        null,
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Asks the SYSTEM whether notification access is on, every single time.
     *
     * The user can revoke it from Android Settings without telling the app, so
     * a cached flag would make the app claim a coverage it does not have
     * (HU-09). `enabled_notification_listeners` is the canonical list of
     * granted listener components.
     */
    private fun isNotificationAccessGranted(): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val ours = ComponentName(context, BilletudoNotificationListenerService::class.java)
        return enabled.split(':').any { entry ->
            val component = ComponentName.unflattenFromString(entry)
            component != null && component == ours
        }
    }

    /**
     * Opens the system screen where the permission is granted. The app can
     * only OPEN it — it cannot grant, pre-select or observe it — so the caller
     * must re-check [isNotificationAccessGranted] when the user comes back.
     */
    private fun openNotificationAccessSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    /**
     * Crosses the closed catalog with the apps actually installed, so the user
     * is only offered issuers that exist on this phone (HU-02).
     *
     * Requires the `<queries>` entries in `AndroidManifest.xml`: since Android
     * 11 an app cannot see another package unless it declares it. A missing
     * entry makes the issuer look "not installed" with no error at all.
     * `QUERY_ALL_PACKAGES` is deliberately NOT used — see the manifest.
     *
     * **The answer is for the screen, not for storage.** This list is computed
     * on demand and discarded: what the user has installed must never be
     * persisted, logged or synced, not even filtered by the catalog and not
     * even as a count. The only package that reaches the database is the one
     * of the issuer that produced a specific capture
     * (`PendingCaptures.sourcePackage`), which is already declared in the
     * Play Data Safety form (App activity -> Installed apps).
     */
    private fun installedIssuerApps(): List<Map<String, Any?>> {
        val ruleSet = IssuerRulesLoader.load(context)
        val enabled = settings.enabledIssuers()
        val packageManager = context.packageManager
        return ruleSet.issuers.mapNotNull { issuer ->
            val installedPackage = issuer.packageNames.firstOrNull { candidate ->
                runCatching { packageManager.getPackageInfo(candidate, 0) }.isSuccess
            } ?: return@mapNotNull null
            mapOf(
                "issuerId" to issuer.issuerId,
                "displayName" to issuer.displayName,
                "packageName" to installedPackage,
                "installed" to true,
                "enabled" to enabled.contains(issuer.issuerId),
            )
        }
    }

    companion object {
        /** Must match `CaptureMethodChannelDatasource.channelName`. */
        const val CHANNEL = "com.billetudo.app/capture"

        /**
         * Must match `CaptureMethodChannelDatasource.incomingCaptureMethod`.
         *
         * It is a doorbell, not a payload: Dart answers it by draining the
         * buffer. Nothing about the notification itself crosses here, so the
         * zero-retention promise is unchanged.
         */
        private const val METHOD_ON_CAPTURE_BUFFERED = "onCaptureBuffered"

        /**
         * No system screen could be opened for a HU-09 action. Flutter turns
         * this into a `Failure`, so the sheet can stay open instead of
         * pretending the setting was shown.
         */
        private const val ERROR_NO_ACTIVITY = "no_activity"

        /**
         * The channel of the Flutter engine currently attached to the app, or
         * `null` when there is none (process started only to deliver a
         * notification, activity destroyed, …).
         *
         * `@Volatile` because [register]/[detach] run on the platform thread
         * while the listener callbacks may be posted from another thread.
         */
        @Volatile
        private var eventsChannel: MethodChannel? = null

        private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

        /**
         * Tells Flutter that the native listener just parked a capture, so it
         * can drain the buffer and update the inbox/badge immediately.
         *
         * **No engine, no event:** when the app process only hosts the
         * service (the common "app closed" case) there is nothing to notify
         * and the capture simply waits in [PendingCaptureBuffer] for the next
         * drain, exactly as before. A dead engine is swallowed here; losing a
         * doorbell is harmless because the app drains on start/resume anyway.
         */
        fun notifyCaptureBuffered() {
            val channel = eventsChannel ?: return
            mainHandler.post {
                runCatching { channel.invokeMethod(METHOD_ON_CAPTURE_BUFFERED, null) }
            }
        }

        /**
         * Called when the Flutter engine goes away, so a later capture does
         * not target a dead messenger.
         */
        fun detach() {
            eventsChannel = null
        }
    }
}
