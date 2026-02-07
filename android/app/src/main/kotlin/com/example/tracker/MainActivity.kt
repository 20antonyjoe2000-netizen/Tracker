package com.example.tracker

import android.app.WallpaperManager
import android.content.Context
import android.os.Build
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.tracker/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val target = call.argument<String>("target") ?: "both"
                    val colorHex = call.argument<String>("color") ?: "#FF9ED9A3"
                    val dotScale = call.argument<Double>("dot_scale") ?: 1.0
                    val spacingScale = call.argument<Double>("spacing_scale") ?: 1.0
                    val verticalOffset = call.argument<Double>("vertical_offset") ?: 0.0
                    val gridScale = call.argument<Double>("grid_scale") ?: 1.0
                    val gridColumns = call.argument<Int>("grid_columns") ?: 12

                    // Save settings for background worker
                    saveWallpaperSettings(target, colorHex, dotScale, spacingScale, verticalOffset, gridScale, gridColumns)
                    
                    val success = setWallpaper(target, colorHex, dotScale, spacingScale, verticalOffset, gridScale, gridColumns)
                    if (success) {
                        scheduleWallpaperUpdate()
                        result.success(true)
                    } else {
                        result.error("WALLPAPER_ERROR", "Failed to set wallpaper", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun saveWallpaperSettings(target: String, colorHex: String, dotScale: Double, spacingScale: Double, verticalOffset: Double, gridScale: Double, gridColumns: Int) {
        val prefs = applicationContext.getSharedPreferences("HomeWidgetPrefs", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putString("wallpaper_target", target)
            putString("primary_color_hex", colorHex)
            putFloat("dot_scale", dotScale.toFloat())
            putFloat("spacing_scale", spacingScale.toFloat())
            putFloat("vertical_offset", verticalOffset.toFloat())
            putFloat("grid_scale", gridScale.toFloat())
            putInt("grid_columns", gridColumns)
            apply()
        }
    }

    private fun scheduleWallpaperUpdate() {
        val workRequest = PeriodicWorkRequestBuilder<WallpaperUpdateWorker>(4, TimeUnit.HOURS)
            .setInitialDelay(1, TimeUnit.HOURS) // Start a bit later to not interfere with current set
            .build()

        WorkManager.getInstance(applicationContext).enqueueUniquePeriodicWork(
            "wallpaper_update",
            ExistingPeriodicWorkPolicy.UPDATE,
            workRequest
        )
    }

    private fun setWallpaper(target: String, colorHex: String, dotScale: Double, spacingScale: Double, verticalOffset: Double, gridScale: Double, gridColumns: Int): Boolean {
        return try {
            val wallpaperManager = WallpaperManager.getInstance(applicationContext)
            val displayMetrics = resources.displayMetrics
            val width = displayMetrics.widthPixels
            val height = displayMetrics.heightPixels

            val bitmap = WallpaperHelper.generateWallpaperBitmap(
                applicationContext, width, height, colorHex, dotScale, spacingScale, verticalOffset, gridScale, gridColumns
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
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
