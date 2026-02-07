import 'dart:math';
import 'package:flutter/material.dart';

/// CustomPainter for rendering the year progress dot grid.
class DotGridPainter extends CustomPainter {
  final int totalDays;
  final int currentDayOfYear;
  final int columns;
  final Color primaryColor;
  final double dotScale;
  final double spacingScale;
  final double verticalOffset; // Relative offset -1.0 to 1.0
  final double gridScale;

  static const Color todayColorOffset = Color(0x33FFFFFF); // Slight highlight for today

  static const Color pastColor = Color(0xFF9ED9A3);
  static const Color todayColor = Color(0xFFB0F0B5);
  static const Color futureColor = Color(0xFF3A3A3A);

  DotGridPainter({
    required this.totalDays,
    required this.currentDayOfYear,
    this.columns = 12,
    this.primaryColor = const Color(0xFF9ED9A3),
    this.dotScale = 1.0,
    this.spacingScale = 1.0,
    this.verticalOffset = 0.0,
    this.gridScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int rows = (totalDays / columns).ceil();

    // Calculate dot size and spacing to fit within a consistent "Safe Area"
    // Use 85% of width and 70% of height as the base for the grid fit
    final double availableWidth = size.width * 0.85 * gridScale;
    final double availableHeight = size.height * 0.70 * gridScale;

    // Base spacing is what fits the grid perfectly into the available area
    final double baseSpacing = min(availableWidth / columns, availableHeight / rows);
    
    // Spacing scale only affects the distance between dots
    final double spacing = baseSpacing * spacingScale;
    
    // Dot size is based on the base fit, not the scaled spacing, so it stays consistent
    final double dotRadius = (baseSpacing * 0.35) * dotScale;
    final double todayDotRadius = dotRadius * 1.12; 

    // Calculate actual grid dimensions after scaling
    final double gridWidth = columns * spacing;
    final double gridHeight = rows * spacing;
    
    // Center relative to the widget'S ACTUAL center, offset by the grid's own size
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    
    final double offsetX = centerX - (gridWidth / 2) + (spacing / 2);
    final double offsetY = centerY - (gridHeight / 2) + (spacing / 2) + (verticalOffset * size.height / 2);

    final Paint pastPaint = Paint()..color = primaryColor;
    final Paint todayPaint = Paint()..color = Color.alphaBlend(todayColorOffset, primaryColor);
    final Paint futurePaint = Paint()..color = futureColor;

    for (int i = 0; i < totalDays; i++) {
      final int row = i ~/ columns;
      final int col = i % columns;
      final double cx = offsetX + col * spacing;
      final double cy = offsetY + row * spacing;

      final int dayNumber = i + 1;

      Paint paint;
      double radius;

      if (dayNumber < currentDayOfYear) {
        paint = pastPaint;
        radius = dotRadius;
      } else if (dayNumber == currentDayOfYear) {
        paint = todayPaint;
        radius = todayDotRadius;
      } else {
        paint = futurePaint;
        radius = dotRadius;
      }

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) {
    return oldDelegate.totalDays != totalDays ||
        oldDelegate.currentDayOfYear != currentDayOfYear ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.dotScale != dotScale ||
        oldDelegate.spacingScale != spacingScale ||
        oldDelegate.verticalOffset != verticalOffset ||
        oldDelegate.gridScale != gridScale ||
        oldDelegate.columns != columns;
  }
}
