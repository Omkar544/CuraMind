package com.example.curamind

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Bundle
import android.util.Log

/**
 * FIXED: Inheriting from FlutterFragmentActivity instead of FlutterActivity.
 * * WHY THIS IS CRITICAL:
 * 1. Resolves the "Build failed due to use of deleted Android v1 embedding" error.
 * 2. Required by the 'health' and 'permission_handler' plugins to cast the 
 * current activity for system dialogs and Health Connect permission checks.
 * 3. Standardizes the app for modern Android API levels (34/35).
 */
class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Log to Logcat to confirm the Activity has started with the correct base class.
        // You can see this in the "Logcat" tab of Android Studio.
        Log.i("CuraMind", "✅ MainActivity initialized successfully with FlutterFragmentActivity (v2 Embedding)")
    }
}