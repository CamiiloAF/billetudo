package com.billetudo.app

import com.billetudo.app.capture.CaptureChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Bank-notification capture (Android only, Fase 2). The channel is the
        // only door to the listener service; the service itself runs without
        // this engine.
        CaptureChannelHandler(applicationContext)
            .register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
