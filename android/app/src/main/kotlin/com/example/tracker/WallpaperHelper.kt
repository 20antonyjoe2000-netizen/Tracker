package com.example.tracker

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Color
import java.util.Calendar
import kotlin.math.ceil
import kotlin.math.min

object WallpaperHelper {
    fun generateWallpaperBitmap(
        context: Context,
        width: Int,
        height: Int,
        colorHex: String,
        dotScale: Double,
        spacingScale: Double,
        verticalOffset: Double,
        gridScale: Double,
        columns: Int
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Fill background with black
        canvas.drawColor(0xFF000000.toInt())

        val now = Calendar.getInstance()
        val year = now.get(Calendar.YEAR)
        val isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
        val totalDays = if (isLeapYear) 366 else 365

        val startOfYear = Calendar.getInstance()
        startOfYear.set(year, Calendar.JANUARY, 1, 0, 0, 0)
        val currentDayOfYear = ((now.timeInMillis - startOfYear.timeInMillis) / (1000 * 60 * 60 * 24)).toInt() + 1

        val rows = ceil(totalDays.toDouble() / columns).toInt()

        val baseWidth = width.toFloat() * 0.85f * gridScale.toFloat()
        val baseHeight = height.toFloat() * 0.70f * gridScale.toFloat()

        val baseSpacing = min(baseWidth / columns, baseHeight / rows)
        val spacing = baseSpacing * spacingScale.toFloat()
        val dotRadius = (baseSpacing * 0.35f) * dotScale.toFloat()
        val todayDotRadius = dotRadius * 1.12f

        val gridWidth = columns * spacing
        val gridHeight = rows * spacing
        
        val offsetX = (width - gridWidth) / 2 + spacing / 2
        val offsetY = (height - gridHeight) / 2 + spacing / 2 + (verticalOffset.toFloat() * height / 2)

        val primaryColor = Color.parseColor(colorHex)
        val pastPaint = Paint().apply {
            color = primaryColor
            isAntiAlias = true
            isDither = true
            isFilterBitmap = true
        }
        val todayPaint = Paint().apply {
            color = primaryColor or 0x33000000 // Subtle highlight
            isAntiAlias = true
            isDither = true
            isFilterBitmap = true
        }
        val futurePaint = Paint().apply {
            color = 0xFF3A3A3A.toInt()
            isAntiAlias = true
            isDither = true
            isFilterBitmap = true
        }

        for (i in 0 until totalDays) {
            val row = i / columns
            val col = i % columns
            val cx = offsetX + col * spacing
            val cy = offsetY + row * spacing

            val dayNumber = i + 1
            val (paint, radius) = when {
                dayNumber < currentDayOfYear -> pastPaint to dotRadius
                dayNumber == currentDayOfYear -> todayPaint to todayDotRadius
                else -> futurePaint to dotRadius
            }

            canvas.drawCircle(cx, cy, radius, paint)
        }

        // Add text at bottom
        val daysRemaining = totalDays - currentDayOfYear
        val daysLived = currentDayOfYear - 1
        val percentageCompleted = (daysLived.toDouble() / totalDays) * 100

        val textPaint = Paint().apply {
            color = 0xFFFFFFFF.toInt()
            textSize = width * 0.12f
            isAntiAlias = true
            isFakeBoldText = true
        }

        val labelPaint = Paint().apply {
            color = 0xFF888888.toInt()
            textSize = width * 0.04f
            isAntiAlias = true
        }

        val percentPaint = Paint().apply {
            color = primaryColor
            textSize = width * 0.08f
            isAntiAlias = true
            isFakeBoldText = true
        }

        val bottomY = height * 0.80f
        val textPadding = width * 0.08f
        canvas.drawText("$daysRemaining", textPadding, bottomY, textPaint)
        canvas.drawText("Days remaining", textPadding, bottomY + width * 0.05f, labelPaint)

        val percentText = String.format("%.1f%%", percentageCompleted)
        val percentWidth = percentPaint.measureText(percentText)
        canvas.drawText(percentText, width - textPadding - percentWidth, bottomY, percentPaint)

        val livedText = "$daysLived days lived"
        val livedWidth = labelPaint.measureText(livedText)
        canvas.drawText(livedText, width - textPadding - livedWidth, bottomY + width * 0.05f, labelPaint)

        return bitmap
    }

    fun generateDotGridBitmap(
        totalDays: Int,
        currentDayOfYear: Int,
        width: Int,
        height: Int,
        primaryColor: Int,
        dotScale: Float,
        spacingScale: Float,
        verticalOffset: Float,
        gridScale: Float,
        columns: Int
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val rows = ceil(totalDays.toDouble() / columns).toInt()

        val baseWidth = width.toFloat() * 0.85f * gridScale
        val baseHeight = height.toFloat() * 0.70f * gridScale

        val baseSpacing = min(baseWidth / columns, baseHeight / rows)
        val spacing = baseSpacing * spacingScale
        val dotRadius = (baseSpacing * 0.35f) * dotScale
        val todayDotRadius = dotRadius * 1.12f

        val gridWidth = columns * spacing
        val gridHeight = rows * spacing
        
        val offsetX = (width - gridWidth) / 2 + spacing / 2
        val offsetY = (height - gridHeight) / 2 + spacing / 2 + (verticalOffset * height / 2)

        val pastPaint = Paint().apply {
            color = primaryColor
            isAntiAlias = true
        }
        val todayPaint = Paint().apply {
            color = primaryColor or 0x33000000 // Subtle highlight
            isAntiAlias = true
        }
        val futurePaint = Paint().apply {
            color = 0xFF3A3A3A.toInt()
            isAntiAlias = true
        }

        for (i in 0 until totalDays) {
            val row = i / columns
            val col = i % columns
            val cx = offsetX + col * spacing
            val cy = offsetY + row * spacing

            val dayNumber = i + 1
            val (paint, radius) = when {
                dayNumber < currentDayOfYear -> pastPaint to dotRadius
                dayNumber == currentDayOfYear -> todayPaint to todayDotRadius
                else -> futurePaint to dotRadius
            }

            canvas.drawCircle(cx, cy, radius, paint)
        }

        return bitmap
    }
}
