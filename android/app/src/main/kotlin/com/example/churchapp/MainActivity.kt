package com.example.churchapp

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
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
}
