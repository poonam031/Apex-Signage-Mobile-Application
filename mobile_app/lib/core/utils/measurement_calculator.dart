class MeasurementResult {
  final double lengthFeet;
  final double heightFeet;
  final double squareFeet;
  final double squareMeters;

  MeasurementResult({
    required this.lengthFeet,
    required this.heightFeet,
    required this.squareFeet,
    required this.squareMeters,
  });
}

class MeasurementCalculator {
  static const double sqFtToSqM = 0.092903;

  /// Calculates Sq.Ft and Sq.Meters automatically
  /// Sq.Ft = Length * Height
  /// Sq.Meter = Sq.Ft * 0.092903
  static MeasurementResult calculate(double length, double height) {
    final sqFt = double.parse((length * height).toStringAsFixed(2));
    final sqM = double.parse((sqFt * sqFtToSqM).toStringAsFixed(3));
    return MeasurementResult(
      lengthFeet: length,
      heightFeet: height,
      squareFeet: sqFt,
      squareMeters: sqM,
    );
  }

  /// Format currency with rupee symbol
  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  /// Format Sq.Ft display
  static String formatSqFt(double sqFt) {
    return '${sqFt.toStringAsFixed(1)} Sq.Ft';
  }
}
