/// Utility class for year progress calculations.
class YearProgressUtils {
  final DateTime _now;

  YearProgressUtils({DateTime? now}) : _now = now ?? DateTime.now();

  /// Returns true if the current year is a leap year.
  bool get isLeapYear {
    final year = _now.year;
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Total days in the current year.
  int get totalDays => isLeapYear ? 366 : 365;

  /// Day of the year (1-indexed).
  int get currentDayOfYear {
    final startOfYear = DateTime(_now.year, 1, 1);
    return _now.difference(startOfYear).inDays + 1;
  }

  /// Days remaining in the year (excluding today).
  int get daysRemaining => totalDays - currentDayOfYear;

  /// Days lived (completed days, excluding today).
  int get daysLived => currentDayOfYear - 1;

  /// Percentage of year completed (based on days lived).
  double get percentageCompleted => (daysLived / totalDays) * 100;
}
