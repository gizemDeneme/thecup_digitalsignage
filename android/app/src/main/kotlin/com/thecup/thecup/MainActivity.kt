package com.thecup.thecup

import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // TV flavor'ında ekran açılışını dinleyen servisi ayağa kaldır (admin'de sınıf yok).
        if (packageName == "com.thecup.tv") {
            val intent = Intent().setClassName(packageName, "com.thecup.tv.WakeService")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent)
            else startService(intent)
        }
    }
}
