package com.thecup.tv

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.thecup.thecup.MainActivity

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in BOOT_ACTIONS) return
        // TV'de yalnızca LEANBACK_LAUNCHER olduğu için getLaunchIntentForPackage null döner;
        // MainActivity'yi doğrudan başlatıyoruz. Android 10+ arka plandan başlatma için
        // SYSTEM_ALERT_WINDOW izni gerekir (adb ile verilir).
        val launchIntent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(launchIntent)
        WakeService.start(context)
    }

    companion object {
        private val BOOT_ACTIONS = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED,
        )
    }
}
