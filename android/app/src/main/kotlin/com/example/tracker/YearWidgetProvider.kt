package com.example.tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import kotlin.math.ceil
import kotlin.math.min

class YearWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val now = Calendar.getInstance()
            val year = now.get(Calendar.YEAR)
            val isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
            val totalDays = if (isLeapYear) 366 else 365

            val startOfYear = Calendar.getInstance()
            startOfYear.set(year, Calendar.JANUARY, 1, 0, 0, 0)
            val currentDayOfYear = ((now.timeInMillis - startOfYear.timeInMillis) / (1000 * 60 * 60 * 24)).toInt() + 1

            val daysRemaining = totalDays - currentDayOfYear
            val daysLived = currentDayOfYear - 1
            val percentageCompleted = (daysLived.toDouble() / totalDays) * 100

            val colorHex = widgetData.getString("primary_color_hex", "#FF9ED9A3") ?: "#FF9ED9A3"
            val primaryColor = android.graphics.Color.parseColor(colorHex)
            val dotScale = widgetData.getFloat("dot_scale", 1.0f)
            val spacingScale = widgetData.getFloat("spacing_scale", 1.0f)
            val verticalOffset = widgetData.getFloat("vertical_offset", 0.0f)
            val gridScale = widgetData.getFloat("grid_scale", 1.0f)

            views.setTextViewText(R.id.days_remaining, "$daysRemaining")
            views.setTextViewText(R.id.percentage, String.format("%.1f%%", percentageCompleted))
            views.setTextColor(R.id.percentage, primaryColor)
            views.setTextViewText(R.id.days_lived, "$daysLived days lived")

            // Generate dot grid bitmap
            val bitmap = WallpaperHelper.generateDotGridBitmap(totalDays, currentDayOfYear, 1024, 1024, primaryColor, dotScale, spacingScale, verticalOffset, gridScale)
            views.setImageViewBitmap(R.id.widget_image, bitmap)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
