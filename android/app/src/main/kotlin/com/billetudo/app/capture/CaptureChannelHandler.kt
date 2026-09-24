package com.billetudo.app.capture

import android.content.ComponentName
import android.content.Context
import android.content.Intent
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

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
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
    }
}
