// ==============================================================================
// FAUNOVA SERVICE: NotificationService
// Layanan notifikasi lokal terjadwal menggunakan flutter_local_notifications
// dan timezone sesuai Plan 5.9 (222-225), Plan 133, 170 & Scope Sesi S18
// ==============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'encrypted_storage_service.dart';
import 'timezone_service.dart';

class NotificationConstants {
  static const int idStreakReminder = 1001;
  static const int idDailyChallengeReminder = 1002;
  static const int idVerifiedExpiryReminder = 1003;
  static const int idInstantTest = 1004;

  static const String channelId = 'faunova_notifications';
  static const String channelName = 'Pengingat Faunova';
  static const String channelDescription =
      'Saluran pengingat streak harian, tantangan biologi satwa, dan masa aktif Centang Biru Faunova.';

  static const String keyStreakReminderEnabled = 'faunova_notif_streak_enabled';
  static const String keyChallengeReminderEnabled = 'faunova_notif_challenge_enabled';
  static const String keyVerifiedExpiryReminderEnabled = 'faunova_notif_verified_enabled';
}

class ScheduledNotificationRecord {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final bool isRecurringDaily;
  final String category;

  const ScheduledNotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.isRecurringDaily,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'scheduled_date': scheduledDate.toIso8601String(),
        'is_recurring_daily': isRecurringDaily,
        'category': category,
      };
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Cache catatan notifikasi terjadwal (berguna untuk testing dan inspeksi UI)
  final Map<int, ScheduledNotificationRecord> _scheduledRecords = {};

  bool get _isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  // ============================================================================
  // INISIALISASI & PERIZINAN (Plan 223)
  // ============================================================================

  /// Inisialisasi flutter_local_notifications dan timezone data
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {}
    } catch (e) {
      debugPrint('NotificationService timezone init error: $e');
    }

    if (_isTestEnvironment) {
      _isInitialized = true;
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      _isInitialized = true;
      debugPrint('NotificationService: Berhasil diinisialisasi.');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
      _isInitialized = true; // Tetap izinkan service berjalan secara graceful
    }
  }

  /// Meminta izin notifikasi (terutama Android 13+ & iOS)
  Future<bool> requestPermissions() async {
    if (_isTestEnvironment) return true;

    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('NotificationService requestPermissions error: $e');
    }

    return false;
  }

  // ============================================================================
  // PENGATURAN TOGGLE NOTIFIKASI LOKAL (EncryptedStorageService)
  // ============================================================================

  bool isStreakReminderEnabled() {
    return EncryptedStorageService.instance.getSetting(
      NotificationConstants.keyStreakReminderEnabled,
      defaultValue: true,
    ) as bool? ?? true;
  }

  Future<void> setStreakReminderEnabled(bool enabled) async {
    await EncryptedStorageService.instance.saveSetting(
      NotificationConstants.keyStreakReminderEnabled,
      enabled,
    );
    if (!enabled) {
      await cancel(NotificationConstants.idStreakReminder);
    } else {
      await scheduleDailyStreakReminder();
    }
  }

  bool isChallengeReminderEnabled() {
    return EncryptedStorageService.instance.getSetting(
      NotificationConstants.keyChallengeReminderEnabled,
      defaultValue: true,
    ) as bool? ?? true;
  }

  Future<void> setChallengeReminderEnabled(bool enabled) async {
    await EncryptedStorageService.instance.saveSetting(
      NotificationConstants.keyChallengeReminderEnabled,
      enabled,
    );
    if (!enabled) {
      await cancel(NotificationConstants.idDailyChallengeReminder);
    } else {
      await scheduleDailyChallengeReminder();
    }
  }

  bool isVerifiedExpiryReminderEnabled() {
    return EncryptedStorageService.instance.getSetting(
      NotificationConstants.keyVerifiedExpiryReminderEnabled,
      defaultValue: true,
    ) as bool? ?? true;
  }

  Future<void> setVerifiedExpiryReminderEnabled(bool enabled, {DateTime? verifiedUntil}) async {
    await EncryptedStorageService.instance.saveSetting(
      NotificationConstants.keyVerifiedExpiryReminderEnabled,
      enabled,
    );
    if (!enabled) {
      await cancel(NotificationConstants.idVerifiedExpiryReminder);
    } else if (verifiedUntil != null) {
      await scheduleVerifiedExpiryReminder(verifiedUntil);
    }
  }

  // ============================================================================
  // PENGINGAT STREAK HARIAN (Plan 170, 223)
  // Malam hari sebelum 24.00 WIB; Dibatalkan jika user sudah check-in
  // ============================================================================

  /// Menjadwalkan pengingat streak harian pada jam 19.00 WIB
  Future<void> scheduleDailyStreakReminder({
    int hour = 19,
    int minute = 0,
    bool forceNextDay = false,
  }) async {
    if (!isStreakReminderEnabled()) return;

    final nowUtc = DateTime.now().toUtc();
    final nowWib = TimeZoneService.toWib(nowUtc);

    // Tentukan waktu target pengingat hari ini di WIB
    DateTime scheduledTime = DateTime(
      nowWib.year,
      nowWib.month,
      nowWib.day,
      hour,
      minute,
    );

    // Jika waktu hari ini sudah terlewat atau diminta force ke esok hari (misal sudah check-in)
    if (forceNextDay || nowWib.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const title = 'Jaga Rekor Observasimu! 🔥';
    const body =
        'Kamu belum melakukan check-in streak hari ini. Buka Faunova dan catat kehadiranmu sebelum 24.00 WIB agar streak tetap menyala!';

    _scheduledRecords[NotificationConstants.idStreakReminder] =
        ScheduledNotificationRecord(
      id: NotificationConstants.idStreakReminder,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      isRecurringDaily: true,
      category: 'streak',
    );

    if (!_isTestEnvironment) {
      try {
        final tzScheduled = tz.TZDateTime.from(
          scheduledTime,
          tz.getLocation('Asia/Jakarta'),
        );

        await _localNotifications.zonedSchedule(
          id: NotificationConstants.idStreakReminder,
          title: title,
          body: body,
          scheduledDate: tzScheduled,
          notificationDetails: _notificationDetails(
            channelId: 'faunova_streak',
            channelName: 'Pengingat Streak Observasi',
            channelDesc: 'Pengingat harian check-in streak satwa',
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('NotificationService scheduleDailyStreakReminder error: $e');
      }
    }

    debugPrint('NotificationService: Pengingat streak dijadwalkan pada $scheduledTime WIB');
  }

  /// Membatalkan notifikasi streak hari ini karena user sudah check-in (Plan 170)
  /// dan otomatis menjadwalkan ulang untuk besok malam.
  Future<void> cancelStreakReminderToday() async {
    await cancel(NotificationConstants.idStreakReminder);
    // Jadwalkan ulang untuk hari berikutnya
    await scheduleDailyStreakReminder(forceNextDay: true);
    debugPrint('NotificationService: Pengingat streak hari ini dibatalkan karena sudah check-in. Dijadwalkan ulang untuk besok.');
  }

  // ============================================================================
  // PENGINGAT TANTANGAN HARI INI (Plan 223)
  // Pagi hari (08.00 WIB)
  // ============================================================================

  /// Menjadwalkan pengingat Tantangan Hari Ini pada jam 08.00 WIB
  Future<void> scheduleDailyChallengeReminder({
    int hour = 8,
    int minute = 0,
    bool forceNextDay = false,
  }) async {
    if (!isChallengeReminderEnabled()) return;

    final nowUtc = DateTime.now().toUtc();
    final nowWib = TimeZoneService.toWib(nowUtc);

    DateTime scheduledTime = DateTime(
      nowWib.year,
      nowWib.month,
      nowWib.day,
      hour,
      minute,
    );

    if (forceNextDay || nowWib.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const title = 'Tantangan Satwa Hari Ini Telah Tiba! 🌿';
    const body =
        'Soal biologi fauna harian baru sudah tersedia di Arena Game. Uji pengetahuanmu dan raih poin observasi hari ini!';

    _scheduledRecords[NotificationConstants.idDailyChallengeReminder] =
        ScheduledNotificationRecord(
      id: NotificationConstants.idDailyChallengeReminder,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      isRecurringDaily: true,
      category: 'challenge',
    );

    if (!_isTestEnvironment) {
      try {
        final tzScheduled = tz.TZDateTime.from(
          scheduledTime,
          tz.getLocation('Asia/Jakarta'),
        );

        await _localNotifications.zonedSchedule(
          id: NotificationConstants.idDailyChallengeReminder,
          title: title,
          body: body,
          scheduledDate: tzScheduled,
          notificationDetails: _notificationDetails(
            channelId: 'faunova_challenge',
            channelName: 'Pengingat Tantangan Harian',
            channelDesc: 'Pengingat soal biologi satwa setiap pagi',
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('NotificationService scheduleDailyChallengeReminder error: $e');
      }
    }

    debugPrint('NotificationService: Pengingat Tantangan Hari Ini dijadwalkan pada $scheduledTime WIB');
  }

  /// Membatalkan notifikasi tantangan harian hari ini karena user sudah menjawab
  Future<void> cancelChallengeReminderToday() async {
    await cancel(NotificationConstants.idDailyChallengeReminder);
    await scheduleDailyChallengeReminder(forceNextDay: true);
    debugPrint('NotificationService: Pengingat tantangan harian dibatalkan hari ini (sudah dijawab). Dijadwalkan untuk esok.');
  }

  // ============================================================================
  // PENGINGAT MASA AKTIF CENTANG BIRU (Plan 133, 223)
  // 3 hari sebelum verified_until berakhir (H-3)
  // ============================================================================

  /// Menjadwalkan pengingat 3 hari sebelum verified_until berakhir
  Future<void> scheduleVerifiedExpiryReminder(DateTime verifiedUntil) async {
    if (!isVerifiedExpiryReminderEnabled()) return;

    final expiryUtc = verifiedUntil.toUtc();
    final reminderUtc = expiryUtc.subtract(const Duration(days: 3));
    final reminderWib = TimeZoneService.toWib(reminderUtc);
    final nowWib = TimeZoneService.toWib(DateTime.now().toUtc());

    // Jika H-3 sudah terlewat atau masa aktif sudah habis
    if (nowWib.isAfter(TimeZoneService.toWib(expiryUtc))) {
      await cancel(NotificationConstants.idVerifiedExpiryReminder);
      return;
    }

    // Jika reminderDate berada di masa lalu tapi expiry masih di masa depan,
    // tampilkan segera (1 jam ke depan)
    final targetScheduleTime = reminderWib.isBefore(nowWib)
        ? nowWib.add(const Duration(minutes: 15))
        : reminderWib;

    final expiryFormatted =
        '${verifiedUntil.day.toString().padLeft(2, '0')}-${verifiedUntil.month.toString().padLeft(2, '0')}-${verifiedUntil.year}';
    final title = 'Langganan Centang Biru Segera Berakhir ⚠️';
    final body =
        'Masa aktif Centang Biru Anda tersisa 3 hari lagi (berakhir $expiryFormatted). Perbarui langganan Anda agar badge dan prioritas pencarian tetap aktif.';

    _scheduledRecords[NotificationConstants.idVerifiedExpiryReminder] =
        ScheduledNotificationRecord(
      id: NotificationConstants.idVerifiedExpiryReminder,
      title: title,
      body: body,
      scheduledDate: targetScheduleTime,
      isRecurringDaily: false,
      category: 'verified',
    );

    if (!_isTestEnvironment) {
      try {
        final tzScheduled = tz.TZDateTime.from(
          targetScheduleTime,
          tz.getLocation('Asia/Jakarta'),
        );

        await _localNotifications.zonedSchedule(
          id: NotificationConstants.idVerifiedExpiryReminder,
          title: title,
          body: body,
          scheduledDate: tzScheduled,
          notificationDetails: _notificationDetails(
            channelId: 'faunova_verified',
            channelName: 'Pengingat Masa Aktif Centang Biru',
            channelDesc: 'Pengingat H-3 sebelum langganan verifikasi berakhir',
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('NotificationService scheduleVerifiedExpiryReminder error: $e');
      }
    }

    debugPrint('NotificationService: Pengingat Centang Biru dijadwalkan pada $targetScheduleTime WIB');
  }

  // ============================================================================
  // NOTIFIKASI LANGSUNG / UJI COBA
  // ============================================================================

  /// Menampilkan notifikasi langsung untuk pengujian instan
  Future<void> showInstantNotification({
    String title = 'Uji Coba Notifikasi Faunova 🦚',
    String body = 'Sistem notifikasi lokal Faunova berjalan sempurna di perangkat Anda!',
  }) async {
    _scheduledRecords[NotificationConstants.idInstantTest] =
        ScheduledNotificationRecord(
      id: NotificationConstants.idInstantTest,
      title: title,
      body: body,
      scheduledDate: DateTime.now(),
      isRecurringDaily: false,
      category: 'test',
    );

    if (!_isTestEnvironment) {
      try {
        await _localNotifications.show(
          id: NotificationConstants.idInstantTest,
          title: title,
          body: body,
          notificationDetails: _notificationDetails(
            channelId: 'faunova_test',
            channelName: 'Uji Notifikasi',
            channelDesc: 'Notifikasi instan untuk verifikasi perangkat',
          ),
        );
      } catch (e) {
        debugPrint('NotificationService showInstantNotification error: $e');
      }
    }
  }

  // ============================================================================
  // PEMBATALAN & KONSISTENSI
  // ============================================================================

  /// Membatalkan notifikasi berdasarkan ID
  Future<void> cancel(int id) async {
    _scheduledRecords.remove(id);
    if (!_isTestEnvironment) {
      try {
        await _localNotifications.cancel(id: id);
      } catch (_) {}
    }
  }

  /// Membatalkan semua notifikasi lokal terjadwal
  Future<void> cancelAll() async {
    _scheduledRecords.clear();
    if (!_isTestEnvironment) {
      try {
        await _localNotifications.cancelAll();
      } catch (_) {}
    }
    debugPrint('NotificationService: Semua notifikasi lokal dibatalkan.');
  }

  /// Memeriksa apakah notifikasi tertentu sedang terjadwal
  bool isNotificationScheduled(int id) {
    return _scheduledRecords.containsKey(id);
  }

  /// Mengambil data catatan notifikasi terjadwal
  ScheduledNotificationRecord? getScheduledRecord(int id) {
    return _scheduledRecords[id];
  }

  /// Mengambil semua notifikasi yang sedang terjadwal
  List<ScheduledNotificationRecord> getAllScheduledRecords() {
    return _scheduledRecords.values.toList();
  }

  /// Helper untuk detail notifikasi Android & iOS
  NotificationDetails _notificationDetails({
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }
}
