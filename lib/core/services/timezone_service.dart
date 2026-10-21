// ==============================================================================
// FAUNOVA SERVICE: TimeZoneService
// Konversi dan penanganan 4 zona waktu: WIB, WITA, WIT, dan London (BST/GMT)
// Sesuai Plan 40, 136, 318 & AGENTS.md (Sesi S12)
// ==============================================================================

enum TimeZoneCode {
  wib,
  wita,
  wit,
  london,
}

class ZoneDisplayData {
  final TimeZoneCode code;
  final String label;
  final String location;
  final String offsetLabel;
  final DateTime localTime;
  final String formattedTime;
  final String formattedDate;
  final String fullString;
  final bool isDaylightSaving;

  const ZoneDisplayData({
    required this.code,
    required this.label,
    required this.location,
    required this.offsetLabel,
    required this.localTime,
    required this.formattedTime,
    required this.formattedDate,
    required this.fullString,
    this.isDaylightSaving = false,
  });
}

class TimeZoneService {
  static final TimeZoneService instance = TimeZoneService._internal();
  TimeZoneService._internal();

  /// Menghitung apakah waktu UTC tertentu berada dalam periode British Summer Time (BST)
  /// BST: Mulai hari Minggu terakhir Maret pk 01:00 UTC sampai Minggu terakhir Oktober pk 01:00 UTC
  static bool isLondonBst(DateTime utcTime) {
    final utc = utcTime.toUtc();
    final year = utc.year;

    // Cari hari Minggu terakhir di bulan Maret
    DateTime marchLastSunday = DateTime.utc(year, 3, 31);
    while (marchLastSunday.weekday != DateTime.sunday) {
      marchLastSunday = marchLastSunday.subtract(const Duration(days: 1));
    }
    final bstStart = DateTime.utc(year, 3, marchLastSunday.day, 1, 0, 0);

    // Cari hari Minggu terakhir di bulan Oktober
    DateTime octoberLastSunday = DateTime.utc(year, 10, 31);
    while (octoberLastSunday.weekday != DateTime.sunday) {
      octoberLastSunday = octoberLastSunday.subtract(const Duration(days: 1));
    }
    final bstEnd = DateTime.utc(year, 10, octoberLastSunday.day, 1, 0, 0);

    return utc.isAfter(bstStart) && utc.isBefore(bstEnd);
  }

  /// Konversi ke WIB (UTC+7)
  static DateTime toWib(DateTime time) {
    return time.toUtc().add(const Duration(hours: 7));
  }

  /// Konversi ke WITA (UTC+8)
  static DateTime toWita(DateTime time) {
    return time.toUtc().add(const Duration(hours: 8));
  }

  /// Konversi ke WIT (UTC+9)
  static DateTime toWit(DateTime time) {
    return time.toUtc().add(const Duration(hours: 9));
  }

  /// Konversi ke London (UTC+0 saat GMT, UTC+1 saat BST)
  static DateTime toLondon(DateTime time) {
    final utc = time.toUtc();
    final bst = isLondonBst(utc);
    return utc.add(Duration(hours: bst ? 1 : 0));
  }

  /// Mendapatkan tanggal kalender WIB (YYYY-MM-DD) saat ini untuk streak & reset kuota harian (Plan 136)
  static DateTime getCurrentDateWib([DateTime? serverTime]) {
    final baseTime = serverTime ?? DateTime.now();
    final wib = toWib(baseTime);
    return DateTime(wib.year, wib.month, wib.day);
  }

  /// String tanggal WIB terstandarisasi 'YYYY-MM-DD'
  static String getCurrentDateWibString([DateTime? serverTime]) {
    final d = getCurrentDateWib(serverTime);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Format data lengkap untuk 4 zona sekaligus
  static List<ZoneDisplayData> getAllZones(DateTime time) {
    final utc = time.toUtc();
    final wib = toWib(utc);
    final wita = toWita(utc);
    final wit = toWit(utc);
    final london = toLondon(utc);
    final bst = isLondonBst(utc);

    String formatDateSafe(DateTime dt) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    String formatTimeSafe(DateTime dt) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    }

    return [
      ZoneDisplayData(
        code: TimeZoneCode.wib,
        label: 'WIB',
        location: 'Jakarta, Sumatra, Jawa',
        offsetLabel: 'UTC+7',
        localTime: wib,
        formattedTime: formatTimeSafe(wib),
        formattedDate: formatDateSafe(wib),
        fullString: '${formatDateSafe(wib)}, ${formatTimeSafe(wib)} WIB',
      ),
      ZoneDisplayData(
        code: TimeZoneCode.wita,
        label: 'WITA',
        location: 'Makassar, Bali, NTB, Kaltim',
        offsetLabel: 'UTC+8',
        localTime: wita,
        formattedTime: formatTimeSafe(wita),
        formattedDate: formatDateSafe(wita),
        fullString: '${formatDateSafe(wita)}, ${formatTimeSafe(wita)} WITA',
      ),
      ZoneDisplayData(
        code: TimeZoneCode.wit,
        label: 'WIT',
        location: 'Jayapura, Maluku, Papua',
        offsetLabel: 'UTC+9',
        localTime: wit,
        formattedTime: formatTimeSafe(wit),
        formattedDate: formatDateSafe(wit),
        fullString: '${formatDateSafe(wit)}, ${formatTimeSafe(wit)} WIT',
      ),
      ZoneDisplayData(
        code: TimeZoneCode.london,
        label: bst ? 'BST' : 'GMT',
        location: 'London, Britania Raya',
        offsetLabel: bst ? 'UTC+1 (BST)' : 'UTC+0 (GMT)',
        localTime: london,
        formattedTime: formatTimeSafe(london),
        formattedDate: formatDateSafe(london),
        fullString: '${formatDateSafe(london)}, ${formatTimeSafe(london)} ${bst ? 'BST' : 'GMT'}',
        isDaylightSaving: bst,
      ),
    ];
  }
}
