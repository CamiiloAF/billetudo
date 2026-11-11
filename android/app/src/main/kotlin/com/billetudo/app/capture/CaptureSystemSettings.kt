package com.billetudo.app.capture

import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import java.util.Locale

/**
 * The two system screens HU-09 offers when the phone may be killing the
 * listener: the battery-optimization exemption and the OEM's "autostart"
 * screen.
 *
 * Neither is required for capture to work, and neither is offered on its own:
 * the app only opens them from the "Captura en segundo plano" sheet, after the
 * user asks to review why notifications may have stopped. The app cannot
 * grant or observe either setting — it can only open the screen — so callers
 * must re-read [isIgnoringBatteryOptimizations] and the capture timestamp when
 * the user comes back.
 *
 * **Nothing here may throw.** OEM screens are frequently renamed, removed or
 * exported-but-refusing across ROM versions, so every launch catches
 * [ActivityNotFoundException] and [SecurityException] and falls back to the
 * next candidate, ending at the app's own details page. A failure to open a
 * screen is a `false` return, never a crash of the app.
 */
class CaptureSystemSettings(private val context: Context) {

    /**
     * Whether Android itself is already leaving this app's process alone.
     *
     * Asked to `PowerManager` on every call, never cached: the user can revoke
     * the exemption from Settings whenever they want, and claiming an
     * exemption that no longer exists is exactly the lie HU-09 forbids.
     */
    fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager =
            context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                ?: return false
        return powerManager.isIgnoringBatteryOptimizations(context.packageName)
    }

    /** The device's manufacturer, verbatim, so the copy can name the brand. */
    fun manufacturer(): String = Build.MANUFACTURER.orEmpty()

    /**
     * Whether this manufacturer exposes a screen worth opening for autostart.
     *
     * `false` for every brand the feature has no destination for: the sheet
     * then hides the row instead of inventing a screen that does not exist
     * (HU-09, "no se inventa un destino").
     */
    fun autostartAvailable(): Boolean = autostartTarget() != AutostartTarget.NONE

    /**
     * Opens the "don't optimize this app's battery" dialog, falling back to the
     * full optimization list when the dialog is unavailable.
     *
     * Returns whether a screen was actually opened.
     *
     * `BatteryLife` is suppressed deliberately: Play flags apps that push
     * users toward this exemption, and this call is justified only because it
     * runs in context, from an explicit user action, for a feature whose
     * failure mode is silent (see the sheet spec).
     */
    @SuppressLint("BatteryLife")
    fun requestIgnoreBatteryOptimizations(): Boolean = openFirstAvailable(
        listOf(
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                .setData(Uri.parse("package:${context.packageName}")),
            // Not every ROM ships the direct dialog; the list always exists.
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
        ),
    )

    /**
     * Opens the manufacturer's autostart screen, falling back to the app's
     * details page on every other brand.
     *
     * Returns whether a screen was actually opened.
     */
    fun openAutostartSettings(): Boolean =
        openFirstAvailable(autostartIntents() + appDetailsIntent())

    /**
     * The OEM-specific candidates, in order. Empty for brands whose autostart
     * screen cannot be deep-linked reliably ([AutostartTarget.APP_DETAILS] and
     * [AutostartTarget.NONE]): those go straight to the app details fallback.
     */
    private fun autostartIntents(): List<Intent> = when (autostartTarget()) {
        AutostartTarget.XIAOMI -> listOf(
            Intent("miui.intent.action.OP_AUTO_START").setComponent(
                ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                ),
            ),
        )

        AutostartTarget.HUAWEI -> listOf(
            componentIntent(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            ),
            // Older EMUI releases expose only this one.
            componentIntent(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.optimize.process.ProtectActivity",
            ),
        )

        AutostartTarget.SAMSUNG -> listOf(
            componentIntent(
                "com.samsung.android.lool",
                "com.samsung.android.sm.ui.battery.BatteryActivity",
            ),
        )

        AutostartTarget.APP_DETAILS, AutostartTarget.NONE -> emptyList()
    }

    /**
     * Which family this device belongs to. Only used to pick a destination;
     * the actual launch still has to succeed.
     *
     * Oppo/Vivo/OnePlus/Realme are `APP_DETAILS` on purpose: their autostart
     * screens are not reliably deep-linkable across models, so claiming a
     * specific component would produce a dead tap.
     */
    private fun autostartTarget(): AutostartTarget {
        val brand = manufacturer().trim().lowercase(Locale.ROOT)
        return when {
            brand.contains("xiaomi") ||
                brand.contains("redmi") ||
                brand.contains("poco") -> AutostartTarget.XIAOMI

            brand.contains("huawei") -> AutostartTarget.HUAWEI
            brand.contains("samsung") -> AutostartTarget.SAMSUNG
            brand.contains("oppo") ||
                brand.contains("vivo") ||
                brand.contains("oneplus") ||
                brand.contains("realme") -> AutostartTarget.APP_DETAILS

            else -> AutostartTarget.NONE
        }
    }

    /**
     * Tries each intent in order until one starts. A rejection is expected, not
     * exceptional: some ROMs keep the activity exported but make it refuse the
     * caller, which surfaces as [SecurityException].
     */
    private fun openFirstAvailable(intents: List<Intent>): Boolean {
        for (intent in intents) {
            val launch = Intent(intent).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                context.startActivity(launch)
                return true
            } catch (_: ActivityNotFoundException) {
                // This ROM does not have that screen: try the next candidate.
            } catch (_: SecurityException) {
                // Present but refusing this caller: same, try the next one.
            }
        }
        return false
    }

    private fun appDetailsIntent(): Intent =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", context.packageName, null))

    private fun componentIntent(packageName: String, className: String): Intent =
        Intent().setComponent(ComponentName(packageName, className))

    private enum class AutostartTarget {
        /** No autostart screen worth opening: hide the row. */
        NONE,

        /** A real system autostart screen exists. */
        XIAOMI,
        HUAWEI,
        SAMSUNG,

        /** Known to have autostart, but only the app details page is reachable. */
        APP_DETAILS,
    }
}
