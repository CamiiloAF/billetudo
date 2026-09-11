package com.billetudo.app.widget

import android.content.Context

/**
 * Per-instance shortcut configuration (HU-03,
 * `docs/requirements/fase-2/20-widget-captura-rapida.md`).
 *
 * Each widget the user adds to the home screen can show a different subset
 * and order of shortcuts — the standard Android App Widget pattern of
 * scoping configuration to `appWidgetId`, not to the app. Backed by a
 * dedicated `SharedPreferences` file; there is no table for this (the widget
 * owns no business data, §Cambios de esquema of the requirement), so Drift
 * never enters the picture.
 */
object WidgetConfigStore {
    private const val PREFS_NAME = "quick_capture_widget_config"
    private const val KEY_PREFIX = "shortcuts_"
    private const val SEPARATOR = ","

    /**
     * Ordered shortcuts for [appWidgetId], or [QuickCaptureShortcut.DEFAULT]
     * when the instance was never configured (or ended up with an empty
     * selection some other way) — the widget must still work on day one
     * (HU-07).
     */
    fun getShortcuts(context: Context, appWidgetId: Int): List<QuickCaptureShortcut> {
        val raw = prefs(context).getString(key(appWidgetId), null)
            ?: return QuickCaptureShortcut.DEFAULT
        val shortcuts = raw.split(SEPARATOR).mapNotNull { QuickCaptureShortcut.fromId(it) }
        return shortcuts.ifEmpty { QuickCaptureShortcut.DEFAULT }
    }

    fun saveShortcuts(context: Context, appWidgetId: Int, shortcuts: List<QuickCaptureShortcut>) {
        prefs(context)
            .edit()
            .putString(key(appWidgetId), shortcuts.joinToString(SEPARATOR) { it.id })
            .apply()
    }

    /** Called from `onDeleted`: an instance's configuration dies with it. */
    fun remove(context: Context, appWidgetId: Int) {
        prefs(context).edit().remove(key(appWidgetId)).apply()
    }

    private fun key(appWidgetId: Int): String = "$KEY_PREFIX$appWidgetId"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
