package com.example.tracker

import android.app.WallpaperManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.work.Worker
import androidx.work.WorkerParameters

class WallpaperUpdateWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
        
        // We only update if a target was previously set
        val target = prefs.getString("wallpaper_target", null) ?: return Result.success()
        val colorHex = prefs.getString("primary_color_hex", "#FF9ED9A3") ?: "#FF9ED9A3"
        val dotScale = prefs.getFloat("dot_scale", 1.0f).toDouble()
        val spacingScale = prefs.getFloat("spacing_scale", 1.0f).toDouble()
        val verticalOffset = prefs.getFloat("vertical_offset", 0.0f).toDouble()
        val gridScale = prefs.getFloat("grid_scale", 1.0f).toDouble()

        try {
            val wallpaperManager = WallpaperManager.getInstance(applicationContext)
            val displayMetrics = applicationContext.resources.displayMetrics
            val width = displayMetrics.widthPixels
            val height = displayMetrics.heightPixels

            val bitmap = WallpaperHelper.generateWallpaperBitmap(
                applicationContext, width, height, colorHex, dotScale, spacingScale, verticalOffset, gridScale
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                when (target) {
                    "home" -> wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                    "lock" -> wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                    else -> {
                        wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK)
                    }
                }
            } else {
                wallpaperManager.setBitmap(bitmap)
            }

            // Trigger widget update
            val intent = Intent(applicationContext, YearWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                val ids = AppWidgetManager.getInstance(applicationContext)
                    .getAppWidgetIds(ComponentName(applicationContext, YearWidgetProvider::class.java))
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            applicationContext.sendBroadcast(intent)

            return Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            return Result.retry()
        }
    }
}
