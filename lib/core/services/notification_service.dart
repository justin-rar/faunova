// ==============================================================================
// FAUNOVA SERVICE: NotificationService
// Layanan notifikasi lokal terjadwal menggunakan flutter_local_notifications
// dan timezone sesuai Plan 5.9 (222-225), Plan 133, 170 & Scope Sesi S18
// ==============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'encrypted_storage_service.dart';
import 'timezone_service.dart';

class NotificationConstants {
  static const int idStreakReminder = 1001;
  static const int idDailyChallengeReminder = 1002;
  static const int idVerifiedExpiryReminder = 1003;
  static const int idInstantTest = 1004;
  static const int idSocialFollow = 1005;
  static const int idSocialLike = 1006;

  static const String channelId = 'faunova_notifications';
  static const String channelName = 'Pengingat Faunova';
  static const String channelDescription =
      'Saluran pengingat streak harian, tantangan biologi satwa, dan masa aktif Centang Biru Faunova.';

  static const String channelSocialId = 'faunova_social';
  static const String channelSocialName = 'Aktivitas Sosial Faunova';
  static const String channelSocialDescription =
      'Pemberitahuan saat postingan disukai atau saat ada pengguna baru mengikuti Anda.';

  static const String keyStreakReminderEnabled = 'faunova_notif_streak_enabled';
  static const String keyChallengeReminderEnabled = 'faunova_notif_challenge_enabled';
  static const String keyVerifiedExpiryReminderEnabled = 'faunova_notif_verified_enabled';
  static const String keySocialNotifEnabled = 'faunova_notif_social_enabled';
}

/// Model data notifikasi aktivitas sosial
class SocialNotificationItem {
  final String id;
  final String recipientUserId;
  final String actorUserId;
  final String actorName;
  final String? actorUsername;
  final String? actorAvatar;
  final String type; // 'follow' | 'like'
  final String? postId;
  final String? speciesName;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const SocialNotificationItem({
    required this.id,
    required this.recipientUserId,
    required this.actorUserId,
    required this.actorName,
    this.actorUsername,
    this.actorAvatar,
    required this.type,
    this.postId,
    this.speciesName,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipient_user_id': recipientUserId,
        'actor_user_id': actorUserId,
        'actor_name': actorName,
        'actor_username': actorUsername,
        'actor_avatar': actorAvatar,
        'type': type,
        'post_id': postId,
        'species_name': speciesName,
        'title': title,
        'body': body,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  factory SocialNotificationItem.fromJson(Map<String, dynamic> json) =>
      SocialNotificationItem(
        id: json['id']?.toString() ?? '',
        recipientUserId:
            (json['recipient_user_id'] ?? json['recipient_id'])?.toString() ?? '',
        actorUserId:
            (json['actor_user_id'] ?? json['actor_id'])?.toString() ?? '',
        actorName: json['actor_name']?.toString() ?? 'Penjelajah Satwa',
        actorUsername: json['actor_username']?.toString(),
        actorAvatar: json['actor_avatar']?.toString(),
        type: json['type']?.toString() ?? 'follow',
        postId: json['post_id']?.toString(),
        speciesName: json['species_name']?.toString(),
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        isRead: json['is_read'] == true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
      );
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

  // Antrean notifikasi sosial per ID pengguna penerima
  final Map<String, List<SocialNotificationItem>> _userNotificationQueues = {};

  RealtimeChannel? _realtimeSubscription;
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  String? _mockCurrentUserId;
  void setMockCurrentUserId(String? id) => _mockCurrentUserId = id;
  String? get mockCurrentUserId => _mockCurrentUserId;

  String? _getCurrentUserId() {
    if (_mockCurrentUserId != null) return _mockCurrentUserId;
    try {
      final client = Supabase.instance.client;
      return client.auth.currentUser?.id ?? client.auth.currentSession?.user.id;
    } catch (_) {
      return null;
    }
  }

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

  bool isSocialNotificationEnabled() {
    return EncryptedStorageService.instance.getSetting(
      NotificationConstants.keySocialNotifEnabled,
      defaultValue: true,
    ) as bool? ?? true;
  }

  Future<void> setSocialNotificationEnabled(bool enabled) async {
    await EncryptedStorageService.instance.saveSetting(
      NotificationConstants.keySocialNotifEnabled,
      enabled,
    );
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

  /// Mendistribusikan notifikasi aktivitas sosial khusus ke pengguna penerima (recipient).
  /// Aturan keras:
  /// 1. Aksi ke diri sendiri (actorUserId == recipientUserId) TIDAK PERNAH membuat notifikasi.
  /// 2. Perangkat pelaku yang melakukan aksi TIDAK PERNAH memunculkan notifikasi lokal.
  /// 3. Notifikasi hanya dimunculkan di perangkat milik pengguna penerima.
  Future<void> dispatchSocialNotification({
    required String recipientUserId,
    required String actorUserId,
    required String actorName,
    required String type, // 'follow' | 'like'
    String? postId,
    String? speciesName,
  }) async {
    // 1. Like/follow ke diri sendiri tidak boleh membuat notifikasi
    if (actorUserId == recipientUserId) {
      debugPrint('NotificationService: Aksi ke diri sendiri diabaikan (actor == recipient: $actorUserId).');
      return;
    }

    final title = type == 'follow'
        ? 'Pengikut Baru! 👥'
        : 'Postingan Anda Disukai! ❤️';

    final body = type == 'follow'
        ? '$actorName mulai mengikuti linimasa satwa Anda.'
        : (speciesName != null && speciesName.isNotEmpty
            ? '$actorName menyukai tangkapan $speciesName Anda.'
            : '$actorName menyukai postingan linimasa Anda.');

    final item = SocialNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      recipientUserId: recipientUserId,
      actorUserId: actorUserId,
      actorName: actorName,
      type: type,
      postId: postId,
      speciesName: speciesName,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );

    // 2. Simpan ke antrean notifikasi pengguna penerima
    _userNotificationQueues[recipientUserId] ??= [];
    _userNotificationQueues[recipientUserId]!.insert(0, item);

    // 3. Simpan ke database Supabase jika sesi aktif tersedia
    if (!_isTestEnvironment) {
      try {
        final client = Supabase.instance.client;
        if (client.auth.currentSession != null) {
          await client.from('notifications').insert({
            'recipient_id': recipientUserId,
            'actor_id': actorUserId,
            'type': type,
            'post_id': postId,
            'title': title,
            'body': body,
          });
        }
      } catch (e) {
        // Graceful fallback jika tabel notifikasi belum termigrasi
        debugPrint('NotificationService insert DB notif note: $e');
      }
    }

    // 4. ATURAN KERAS: Perangkat PELAKU yang menekan tombol TIDAK PERNAH memunculkan notifikasi!
    final currentUserId = _getCurrentUserId();
    if (currentUserId != null && currentUserId == actorUserId) {
      debugPrint('NotificationService: Notifikasi untuk $recipientUserId tersimpan, HP pelaku ($actorUserId) tidak memunculkan notifikasi.');
      return;
    }

    // 5. Jika perangkat yang sedang berjalan saat ini adalah perangkat penerima:
    if (currentUserId != null && currentUserId == recipientUserId) {
      await _deliverLocalSocialNotification(item);
    }
  }

  /// Mengirimkan notifikasi lokal tertunda khusus untuk user penerima saat membuka aplikasi
  Future<List<SocialNotificationItem>> deliverPendingNotificationsForUser(String userId) async {
    if (!isSocialNotificationEnabled()) return [];

    final queue = _userNotificationQueues[userId] ?? [];
    final unread = queue.where((item) => !item.isRead).toList();

    for (final item in unread) {
      await _deliverLocalSocialNotification(item);
      final idx = queue.indexWhere((q) => q.id == item.id);
      if (idx != -1) {
        queue[idx] = SocialNotificationItem(
          id: item.id,
          recipientUserId: item.recipientUserId,
          actorUserId: item.actorUserId,
          actorName: item.actorName,
          type: item.type,
          postId: item.postId,
          speciesName: item.speciesName,
          title: item.title,
          body: item.body,
          isRead: true,
          createdAt: item.createdAt,
        );
      }
    }
    return queue;
  }

  /// Mengambil daftar notifikasi milik pengguna tertentu dengan filter penerima
  List<SocialNotificationItem> fetchMyNotifications(String userId) {
    final list = _userNotificationQueues[userId] ?? [];
    return list.where((n) => n.recipientUserId == userId && n.actorUserId != userId).toList();
  }

  /// Membersihkan antrean notifikasi sosial (untuk testing)
  void clearNotificationQueues() {
    _userNotificationQueues.clear();
    unreadCountNotifier.value = 0;
  }

  /// Menginisialisasi listener Supabase Realtime untuk notifikasi masuk khusus pengguna ini
  Future<void> initRealtimeListener(String userId) async {
    if (_isTestEnvironment || userId.isEmpty) return;

    try {
      if (_realtimeSubscription != null) {
        await _realtimeSubscription?.unsubscribe();
        _realtimeSubscription = null;
      }

      final client = Supabase.instance.client;
      _realtimeSubscription = client
          .channel('public:notifications:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'recipient_id',
              value: userId,
            ),
            callback: (payload) async {
              debugPrint('NotificationService Realtime incoming: ${payload.newRecord}');
              final record = payload.newRecord;
              final actorId = (record['actor_id'] ?? '').toString();
              final recipientId = (record['recipient_id'] ?? '').toString();

              // Aturan keras: Pelaku sendiri tidak boleh menerima notifikasi
              final currentUserId = _getCurrentUserId();
              if (actorId == userId || actorId == recipientId || currentUserId == actorId) {
                return;
              }

              // Ambil profil actor untuk avatar/nama jika belum lengkap
              String actorName = 'Penjelajah Satwa';
              String? actorUsername;
              String? actorAvatar;
              try {
                final prof = await client
                    .from('profiles')
                    .select('display_name, username, avatar_path')
                    .eq('id', actorId)
                    .maybeSingle();
                if (prof != null) {
                  actorName = (prof['display_name'] as String?) ??
                      (prof['username'] as String?) ??
                      actorName;
                  actorUsername = prof['username'] as String?;
                  actorAvatar = prof['avatar_path'] as String?;
                }
              } catch (_) {}

              final item = SocialNotificationItem(
                id: record['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                recipientUserId: recipientId,
                actorUserId: actorId,
                actorName: actorName,
                actorUsername: actorUsername,
                actorAvatar: actorAvatar,
                type: record['type']?.toString() ?? 'follow',
                postId: record['post_id']?.toString(),
                title: record['title']?.toString() ?? 'Pemberitahuan Baru',
                body: record['body']?.toString() ?? '',
                isRead: false,
                createdAt: record['created_at'] != null
                    ? DateTime.parse(record['created_at'].toString())
                    : DateTime.now(),
              );

              // 1. Simpan ke antrean memori lokal penerima
              _userNotificationQueues[userId] ??= [];
              final exists = _userNotificationQueues[userId]!.any((n) => n.id == item.id);
              if (!exists) {
                _userNotificationQueues[userId]!.insert(0, item);
                unreadCountNotifier.value++;
              }

              // 2. Tampilkan banner notifikasi lokal di layar HP penerima
              if (isSocialNotificationEnabled()) {
                await _deliverLocalSocialNotification(item);
              }
            },
          );
      _realtimeSubscription!.subscribe();
      debugPrint('NotificationService: Supabase Realtime aktif untuk recipient $userId');
    } catch (e) {
      debugPrint('NotificationService initRealtimeListener error: $e');
    }
  }

  /// Menutup langganan Realtime
  Future<void> disposeRealtimeListener() async {
    if (_realtimeSubscription != null) {
      try {
        await _realtimeSubscription?.unsubscribe();
      } catch (_) {}
      _realtimeSubscription = null;
    }
  }

  /// Menarik daftar notifikasi pengguna dari Supabase RPC get_my_notifications
  Future<List<SocialNotificationItem>> fetchServerNotifications({int limit = 30}) async {
    final myId = _getCurrentUserId();
    if (myId == null) return [];

    if (_isTestEnvironment) {
      return fetchMyNotifications(myId);
    }

    try {
      final client = Supabase.instance.client;
      final response = await client.rpc(
        'get_my_notifications',
        params: {'p_limit': limit},
      );

      final List<dynamic> rows = response as List<dynamic>;
      final list = rows
          .map((r) => SocialNotificationItem.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();

      _userNotificationQueues[myId] = list;
      unreadCountNotifier.value = list.where((n) => !n.isRead).length;
      return list;
    } catch (e) {
      debugPrint('NotificationService fetchServerNotifications error: $e');
      return fetchMyNotifications(myId);
    }
  }

  /// Menandai seluruh notifikasi pengguna aktif sebagai telah dibaca
  Future<void> markAllAsRead() async {
    final myId = _getCurrentUserId();
    if (myId == null) return;

    unreadCountNotifier.value = 0;
    final queue = _userNotificationQueues[myId];
    if (queue != null) {
      for (int i = 0; i < queue.length; i++) {
        if (!queue[i].isRead) {
          queue[i] = SocialNotificationItem(
            id: queue[i].id,
            recipientUserId: queue[i].recipientUserId,
            actorUserId: queue[i].actorUserId,
            actorName: queue[i].actorName,
            actorUsername: queue[i].actorUsername,
            actorAvatar: queue[i].actorAvatar,
            type: queue[i].type,
            postId: queue[i].postId,
            speciesName: queue[i].speciesName,
            title: queue[i].title,
            body: queue[i].body,
            isRead: true,
            createdAt: queue[i].createdAt,
          );
        }
      }
    }

    if (!_isTestEnvironment) {
      try {
        final client = Supabase.instance.client;
        await client
            .from('notifications')
            .update({'is_read': true})
            .eq('recipient_id', myId)
            .eq('is_read', false);
      } catch (e) {
        debugPrint('NotificationService markAllAsRead error: $e');
      }
    }
  }

  Future<void> _deliverLocalSocialNotification(SocialNotificationItem item) async {
    final notifId = item.type == 'follow'
        ? NotificationConstants.idSocialFollow
        : NotificationConstants.idSocialLike;

    _scheduledRecords[notifId] = ScheduledNotificationRecord(
      id: notifId,
      title: item.title,
      body: item.body,
      scheduledDate: DateTime.now(),
      isRecurringDaily: false,
      category: item.type == 'follow' ? 'social_follow' : 'social_like',
    );

    if (!_isTestEnvironment) {
      try {
        await _localNotifications.show(
          id: notifId,
          title: item.title,
          body: item.body,
          notificationDetails: _notificationDetails(
            channelId: NotificationConstants.channelSocialId,
            channelName: NotificationConstants.channelSocialName,
            channelDesc: NotificationConstants.channelSocialDescription,
          ),
        );
      } catch (e) {
        debugPrint('NotificationService _deliverLocalSocialNotification error: $e');
      }
    }
  }

  /// Menampilkan notifikasi instan ketika ada pengguna baru mengikuti akun kita (hanya jika di perangkat penerima)
  Future<void> showFollowNotification({
    required String followerName,
    String? recipientUserId,
    String? actorUserId,
  }) async {
    if (!isSocialNotificationEnabled()) return;

    final currentUserId = _getCurrentUserId();
    // Aturan keras: Jangan pernah tampilkan di HP pelaku
    if (actorUserId != null && currentUserId != null && actorUserId == currentUserId) {
      return;
    }
    if (recipientUserId != null && currentUserId != null && recipientUserId != currentUserId) {
      return;
    }

    final title = 'Pengikut Baru! 👥';
    final body = '$followerName mulai mengikuti linimasa satwa Anda.';

    _scheduledRecords[NotificationConstants.idSocialFollow] =
        ScheduledNotificationRecord(
      id: NotificationConstants.idSocialFollow,
      title: title,
      body: body,
      scheduledDate: DateTime.now(),
      isRecurringDaily: false,
      category: 'social_follow',
    );

    if (!_isTestEnvironment) {
      try {
        await _localNotifications.show(
          id: NotificationConstants.idSocialFollow,
          title: title,
          body: body,
          notificationDetails: _notificationDetails(
            channelId: NotificationConstants.channelSocialId,
            channelName: NotificationConstants.channelSocialName,
            channelDesc: NotificationConstants.channelSocialDescription,
          ),
        );
      } catch (e) {
        debugPrint('NotificationService showFollowNotification error: $e');
      }
    }
  }

  /// Menampilkan notifikasi instan ketika ada yang menyukai postingan linimasa kita (hanya jika di perangkat penerima)
  Future<void> showLikeNotification({
    required String likerName,
    String? speciesName,
    String? recipientUserId,
    String? actorUserId,
  }) async {
    if (!isSocialNotificationEnabled()) return;

    final currentUserId = _getCurrentUserId();
    // Aturan keras: Jangan pernah tampilkan di HP pelaku
    if (actorUserId != null && currentUserId != null && actorUserId == currentUserId) {
      return;
    }
    if (recipientUserId != null && currentUserId != null && recipientUserId != currentUserId) {
      return;
    }

    final title = 'Postingan Anda Disukai! ❤️';
    final body = speciesName != null && speciesName.isNotEmpty
        ? '$likerName menyukai tangkapan $speciesName Anda.'
        : '$likerName menyukai postingan linimasa Anda.';

    _scheduledRecords[NotificationConstants.idSocialLike] =
        ScheduledNotificationRecord(
      id: NotificationConstants.idSocialLike,
      title: title,
      body: body,
      scheduledDate: DateTime.now(),
      isRecurringDaily: false,
      category: 'social_like',
    );

    if (!_isTestEnvironment) {
      try {
        await _localNotifications.show(
          id: NotificationConstants.idSocialLike,
          title: title,
          body: body,
          notificationDetails: _notificationDetails(
            channelId: NotificationConstants.channelSocialId,
            channelName: NotificationConstants.channelSocialName,
            channelDesc: NotificationConstants.channelSocialDescription,
          ),
        );
      } catch (e) {
        debugPrint('NotificationService showLikeNotification error: $e');
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
