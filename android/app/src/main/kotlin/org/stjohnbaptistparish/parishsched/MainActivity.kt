package org.stjohnbaptistparish.parishsched

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth
// for the fingerprint / device-PIN prompt.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Overrides this activity's own enter transition with "no
        // animation", regardless of what the launcher (XOS) requested when
        // it started us -- this is a real, documented Android API for the
        // activity being opened to override its transition, separate from
        // (and untried until now) the assumption that only the caller
        // controls it.
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets screens showing personal data (login, reservations, ...)
        // block screenshots, screen recording and the recent-apps preview
        // (see lib/security/secure_screen.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "parishsched/secure_screen")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "disable" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
