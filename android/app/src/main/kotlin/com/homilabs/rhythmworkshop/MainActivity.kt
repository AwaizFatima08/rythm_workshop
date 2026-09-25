package com.homilabs.rhythmworkshop

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Keeps the screen on while a level, reward or goodnight scene is showing.
        // A window flag: no permission and no extra package needed.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rhythm_workshop/screen")
            .setMethodCallHandler { call, result ->
                if (call.method == "keepOn") {
                    val flag = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    if (call.arguments as Boolean) window.addFlags(flag) else window.clearFlags(flag)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
