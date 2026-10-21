import 'dart:math' as math;

/// Enum 8 Arah Mata Angin resmi Faunova sesuai Dokumen Desain 5.10
enum CardinalDirection {
  utara('U', 'Utara', 0.0),
  timurLaut('TL', 'Timur Laut', 45.0),
  timur('T', 'Timur', 90.0),
  tenggara('TG', 'Tenggara', 135.0),
  selatan('S', 'Selatan', 180.0),
  baratDaya('BD', 'Barat Daya', 225.0),
  barat('B', 'Barat', 270.0),
  baratLaut('BL', 'Barat Laut', 315.0);

  final String code;
  final String labelId;
  final double degrees;

  const CardinalDirection(this.code, this.labelId, this.degrees);
}

/// Layanan penghitungan dan kalibrasi arah kompas (camera heading)
/// Mengonversi derajat menjadi 8 mata angin dan menghitung selisih sudut untuk pengujian di HP fisik.
class CompassHeadingService {
  CompassHeadingService._();

  /// Menormalkan sudut derajat ke rentang 0.0 <= degrees < 360.0
  static double normalizeDegrees(double degrees) {
    var result = degrees % 360.0;
    if (result < 0) {
      result += 360.0;
    }
    return result;
  }

  /// Alias untuk normalizeDegrees
  static double normalizeHeading(double degrees) => normalizeDegrees(degrees);

  /// Mengonversi nilai heading derajat menjadi [CardinalDirection] (8 mata angin)
  static CardinalDirection degreesToCardinal(double degrees) {
    final norm = normalizeDegrees(degrees);

    if (norm >= 337.5 || norm < 22.5) {
      return CardinalDirection.utara;
    } else if (norm >= 22.5 && norm < 67.5) {
      return CardinalDirection.timurLaut;
    } else if (norm >= 67.5 && norm < 112.5) {
      return CardinalDirection.timur;
    } else if (norm >= 112.5 && norm < 157.5) {
      return CardinalDirection.tenggara;
    } else if (norm >= 157.5 && norm < 202.5) {
      return CardinalDirection.selatan;
    } else if (norm >= 202.5 && norm < 247.5) {
      return CardinalDirection.baratDaya;
    } else if (norm >= 247.5 && norm < 292.5) {
      return CardinalDirection.barat;
    } else {
      return CardinalDirection.baratLaut;
    }
  }

  /// Menghasilkan format HUD taktis ringkas (contoh: "148° TG" atau "0° U")
  static String formatHud(double degrees) {
    final norm = normalizeDegrees(degrees);
    final cardinal = degreesToCardinal(norm);
    final rounded = norm.round() % 360;
    return '$rounded° ${cardinal.code}';
  }

  /// Menghasilkan format teks bahasa Indonesia lengkap (contoh: "Menghadap Tenggara (148°)")
  static String formatFullDescription(double degrees) {
    final norm = normalizeDegrees(degrees);
    final cardinal = degreesToCardinal(norm);
    final rounded = norm.round() % 360;
    return 'Menghadap ${cardinal.labelId} ($rounded°)';
  }

  /// Alias untuk formatFullDescription
  static String formatDetailed(double degrees) => formatFullDescription(degrees);

  /// Menghitung selisih sudut terkecil antara dua heading (dalam derajat 0..180)
  /// Digunakan untuk evaluasi batas toleransi 20° pada HP fisik sesuai Plan 5.10
  static double angularDifference(double angleA, double angleB) {
    final diff = (normalizeDegrees(angleA) - normalizeDegrees(angleB)).abs();
    return math.min(diff, 360.0 - diff);
  }

  /// Memeriksa apakah selisih heading memenuhi ambang batas toleransi (default 20.0°)
  static bool isWithinTolerance(
    double sensorHeading,
    double referenceHeading, {
    double toleranceDegrees = 20.0,
  }) {
    return angularDifference(sensorHeading, referenceHeading) <= toleranceDegrees;
  }
}
