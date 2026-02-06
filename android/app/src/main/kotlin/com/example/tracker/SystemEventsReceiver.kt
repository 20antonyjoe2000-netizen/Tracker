package com.example.tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class SystemEventsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val prefs = context.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
        val target = prefs.getString("wallpaper_target", null)
        
        if (target != null) {
            when (action) {
                Intent.ACTION_BOOT_COMPLETED -> {
                    // Reschedule periodic work on boot
                    val workRequest = PeriodicWorkRequestBuilder<WallpaperUpdateWorker>(4, TimeUnit.HOURS)
                        .build()

                    WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                        "wallpaper_update",
                        ExistingPeriodicWorkPolicy.UPDATE,
                        workRequest
                    )
                }
                Intent.ACTION_DATE_CHANGED, "android.intent.action.TIME_SET", Intent.ACTION_TIMEZONE_CHANGED -> {
                    // Trigger an immediate one-time update
                    val immediateRequest = OneTimeWorkRequestBuilder<WallpaperUpdateWorker>()
                        .build()
                    
                    WorkManager.getInstance(context).enqueueUniqueWork(
                        "immediate_wallpaper_update",
                        ExistingWorkPolicy.REPLACE,
                        immediateRequest
                    )
                }
            }
        }
    }
}
