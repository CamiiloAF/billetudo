package com.billetudo.app.widget

import android.content.Intent
import io.flutter.plugin.common.MethodChannel

/**
 * Hands the tapped widget shortcut to Dart
 * (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
 *
 * Written by hand instead of using the `home_widget` package: with the
 * pure-shortcut scope there is no shared data store to write, so the whole
 * bridge is one string travelling one way. The channel name and the two
 * method names mirror
 * `lib/features/capture/data/datasources/capture_shortcut_channel_datasource.dart`.
 *
 * A cold start and a warm resume take different paths on purpose: on a cold
 * start Dart is not listening yet, so the id waits in [pendingShortcutId]
 * until Dart asks for it with `getInitialShortcut`; once the engine is up,
 * `onNewIntent` pushes it with `onShortcut`.
 */
object QuickCaptureWidgetBridge {
    const val CHANNEL = "com.billetudo.app/capture_shortcuts"
    const val ACTION_OPEN_SHORTCUT = "com.billetudo.app.widget.OPEN_SHORTCUT"
    const val EXTRA_SHORTCUT = "com.billetudo.app.widget.EXTRA_SHORTCUT"

    private const val METHOD_GET_INITIAL = "getInitialShortcut"
    private const val METHOD_ON_SHORTCUT = "onShortcut"

    private var pendingShortcutId: String? = null

    /** The shortcut id [intent] carries, or `null` for a normal launch. */
    fun shortcutIdFrom(intent: Intent?): String? {
        if (intent?.action != ACTION_OPEN_SHORTCUT) {
            return null
        }
        return QuickCaptureShortcut.fromId(intent.getStringExtra(EXTRA_SHORTCUT))?.id
    }

    /** Remembers a launch shortcut until Dart is ready to ask for it. */
    fun holdForColdStart(shortcutId: String?) {
        if (shortcutId != null) {
            pendingShortcutId = shortcutId
        }
    }

    /**
     * Delivers [shortcutId] to a running Dart side. Returns `false` when
     * there is no live channel yet, so the caller can hold it instead.
     */
    fun deliver(channel: MethodChannel?, shortcutId: String): Boolean {
        if (channel == null) {
            return false
        }
        channel.invokeMethod(METHOD_ON_SHORTCUT, shortcutId)
        return true
    }

    /**
     * Wires the channel's Dart→native side. Reading the pending id also
     * clears it: a hot restart or a later resume must not replay a tap the
     * user already got their form for.
     */
    fun attach(channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            if (call.method == METHOD_GET_INITIAL) {
                val shortcutId = pendingShortcutId
                pendingShortcutId = null
                result.success(shortcutId)
            } else {
                result.notImplemented()
            }
        }
    }
}
