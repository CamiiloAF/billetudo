package com.billetudo.app

import android.content.Intent
import com.billetudo.app.capture.CaptureChannelHandler
import com.billetudo.app.widget.QuickCaptureWidgetBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var captureShortcutChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QuickCaptureWidgetBridge.CHANNEL,
        )
        QuickCaptureWidgetBridge.attach(channel)
        captureShortcutChannel = channel
        // The intent that started this activity is read here, not in
        // `onCreate`: at this point Dart has not run yet, so the shortcut is
        // held until Dart asks for it (cold start, HU-01).
        QuickCaptureWidgetBridge.holdForColdStart(
            QuickCaptureWidgetBridge.shortcutIdFrom(intent),
        )
        // Bank-notification capture (Android only, Fase 2). The channel is the
        // only door to the listener service; the service itself runs without
        // this engine.
        CaptureChannelHandler(applicationContext)
            .register(flutterEngine.dartExecutor.binaryMessenger)
    }

    /** A widget tap while the app was already alive (`singleTop`). */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val shortcutId = QuickCaptureWidgetBridge.shortcutIdFrom(intent) ?: return
        if (!QuickCaptureWidgetBridge.deliver(captureShortcutChannel, shortcutId)) {
            QuickCaptureWidgetBridge.holdForColdStart(shortcutId)
        }
    }

    override fun onDestroy() {
        captureShortcutChannel = null
        super.onDestroy()
    }
}
