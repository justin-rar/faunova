// ==============================================================================
// FAUNOVA WIDGET: NotificationSettingSheet
// Lembar pengaturan notifikasi lokal terjadwal sesuai Plan 5.9 (222-225) & Sesi S18
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationSettingSheet extends StatefulWidget {
  const NotificationSettingSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationSettingSheet(),
    );
  }

  @override
  State<NotificationSettingSheet> createState() => _NotificationSettingSheetState();
}

class _NotificationSettingSheetState extends State<NotificationSettingSheet> {
  bool _isLoading = true;
  bool _streakEnabled = true;
  bool _challengeEnabled = true;
  bool _verifiedEnabled = true;
  bool _socialEnabled = true;
  bool _isCheckedInToday = false;
  DateTime? _verifiedUntil;
  List<ScheduledNotificationRecord> _activeRecords = [];

  @override
  void initState() {
    super.initState();
    _loadNotificationData();
  }

  Future<void> _loadNotificationData() async {
    setState(() => _isLoading = true);

    final streakEn = NotificationService.instance.isStreakReminderEnabled();
    final challengeEn = NotificationService.instance.isChallengeReminderEnabled();
    final verifiedEn = NotificationService.instance.isVerifiedExpiryReminderEnabled();
    final socialEn = NotificationService.instance.isSocialNotificationEnabled();

    // Cek status streak hari ini
    bool checkedIn = false;
    try {
      final status = await StreakService.instance.getStreakStatus();
      checkedIn = status.isClaimedToday;
    } catch (_) {}

    // Cek status masa aktif verified
    DateTime? verifiedExpiry;
    try {
      final myProfile = await ProfileService.instance.getMyProfile();
      if (myProfile.isVerifiedActive) {
        verifiedExpiry = myProfile.verifiedUntil ?? DateTime.now().add(const Duration(days: 28));
      }
    } catch (_) {}

    final records = NotificationService.instance.getAllScheduledRecords();

    if (mounted) {
      setState(() {
        _streakEnabled = streakEn;
        _challengeEnabled = challengeEn;
        _verifiedEnabled = verifiedEn;
        _socialEnabled = socialEn;
        _isCheckedInToday = checkedIn;
        _verifiedUntil = verifiedExpiry;
        _activeRecords = records;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStreak(bool val) async {
    setState(() => _streakEnabled = val);
    await NotificationService.instance.setStreakReminderEnabled(val);
    _refreshRecords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val
              ? 'Pengingat streak harian (19:00 WIB) diaktifkan.'
              : 'Pengingat streak dinonaktifkan.'),
          backgroundColor: AppColors.sageTua,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleChallenge(bool val) async {
    setState(() => _challengeEnabled = val);
    await NotificationService.instance.setChallengeReminderEnabled(val);
    _refreshRecords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val
              ? 'Pengingat Tantangan Hari Ini (08:00 WIB) diaktifkan.'
              : 'Pengingat tantangan harian dinonaktifkan.'),
          backgroundColor: AppColors.sageTua,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleVerified(bool val) async {
    setState(() => _verifiedEnabled = val);
    await NotificationService.instance.setVerifiedExpiryReminderEnabled(
      val,
      verifiedUntil: _verifiedUntil,
    );
    _refreshRecords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val
              ? 'Pengingat H-3 Centang Biru diaktifkan.'
              : 'Pengingat Centang Biru dinonaktifkan.'),
          backgroundColor: AppColors.sageTua,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleSocial(bool val) async {
    setState(() => _socialEnabled = val);
    await NotificationService.instance.setSocialNotificationEnabled(val);
    _refreshRecords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val
              ? 'Notifikasi aktivitas sosial (suka & pengikut) diaktifkan.'
              : 'Notifikasi aktivitas sosial dinonaktifkan.'),
          backgroundColor: AppColors.sageTua,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _refreshRecords() {
    setState(() {
      _activeRecords = NotificationService.instance.getAllScheduledRecords();
    });
  }

  Future<void> _sendTestNotification() async {
    final granted = await NotificationService.instance.requestPermissions();
    await NotificationService.instance.showInstantNotification();
    _refreshRecords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Notifikasi percobaan berhasil dikirim ke perangkat!'
                : 'Notifikasi dikirim! Pastikan izin notifikasi diizinkan di sistem HP Anda.',
          ),
          backgroundColor: AppColors.sageTua,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sage.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sageTua.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.sageTua,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Notifikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.teksGelap,
                        ),
                      ),
                      Text(
                        'Pengingat observasi satwa & langganan lokal',
                        style: TextStyle(fontSize: 11, color: AppColors.teksGelap),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.teksGelap),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2DDD3)),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sageTua),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Banner Info Offline
                      _buildOfflineBanner(),
                      const SizedBox(height: 16),

                      // 1. Pengingat Streak
                      _buildSettingCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFE65100),
                        title: 'Pengingat Streak Harian (19:00 WIB)',
                        subtitle:
                            'Mengirim pengingat malam hari sebelum 24.00 WIB jika Anda belum check-in. Otomatis dibatalkan jika Anda sudah check-in hari ini.',
                        value: _streakEnabled,
                        onChanged: _toggleStreak,
                        extraBadge: _isCheckedInToday
                            ? Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.sage.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 13, color: AppColors.sageTua),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Sudah Check-in Hari Ini (Notifikasi Malam Dibatalkan)',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.sageTua,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // 2. Pengingat Tantangan Hari Ini
                      _buildSettingCard(
                        icon: Icons.quiz_rounded,
                        iconColor: AppColors.sageTua,
                        title: 'Tantangan Satwa Hari Ini (08:00 WIB)',
                        subtitle:
                            'Mengirim pengingat pagi hari saat soal biologi satwa baru tersedia di Arena Game.',
                        value: _challengeEnabled,
                        onChanged: _toggleChallenge,
                      ),
                      const SizedBox(height: 12),

                      // 3. Pengingat Masa Aktif Centang Biru (H-3)
                      _buildSettingCard(
                        icon: Icons.verified_rounded,
                        iconColor: const Color(0xFF1976D2),
                        title: 'Masa Aktif Centang Biru (H-3)',
                        subtitle:
                            'Pengingat 3 hari sebelum langganan Centang Biru Anda berakhir, agar badge verifikasi dan prioritas pencarian tetap aktif.',
                        value: _verifiedEnabled,
                        onChanged: _toggleVerified,
                        extraBadge: _verifiedUntil != null
                            ? Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1976D2).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Berakhir: ${_verifiedUntil!.day}-${_verifiedUntil!.month}-${_verifiedUntil!.year}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // 4. Notifikasi Sosial (Suka & Pengikut)
                      _buildSettingCard(
                        icon: Icons.favorite_rounded,
                        iconColor: const Color(0xFFE91E63),
                        title: 'Aktivitas Sosial (Suka & Pengikut)',
                        subtitle:
                            'Pemberitahuan instan ketika ada pengguna baru mengikuti Anda atau menyukai tangkapan satwa di linimasa.',
                        value: _socialEnabled,
                        onChanged: _toggleSocial,
                      ),
                      const SizedBox(height: 20),

                      // Daftar Jadwal Aktif
                      _buildActiveScheduleSection(),
                      const SizedBox(height: 20),

                      // Tombol Kirim Notifikasi Uji Coba
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _sendTestNotification,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text(
                            'Kirim Notifikasi Percobaan',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emas,
                            foregroundColor: AppColors.teksGelap,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.teksGelap,
                          side: const BorderSide(color: AppColors.sage),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sageMuda.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.sageTua),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifikasi Lokal Mandiri (Plan 223)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.teksGelap,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Notifikasi dijadwalkan langsung di sistem operasi perangkat Anda. Tetap berbunyi tepat waktu meskipun tanpa koneksi internet.',
                  style: TextStyle(fontSize: 11, color: AppColors.teksGelap),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? extraBadge,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sageMuda.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.teksGelap,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.emas,
                activeTrackColor: AppColors.sageTua,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.teksGelap.withValues(alpha: 0.75),
              height: 1.35,
            ),
          ),
          ?extraBadge,
        ],
      ),
    );
  }

  Widget _buildActiveScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sageMuda.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sageMuda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm_on_rounded, size: 18, color: AppColors.sageTua),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Jadwal Alarm Notifikasi Aktif',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.teksGelap,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.sageTua,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_activeRecords.length} Aktif',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_activeRecords.isEmpty)
            const Text(
              'Belum ada notifikasi yang dijadwalkan.',
              style: TextStyle(fontSize: 11, color: AppColors.teksGelap),
            )
          else
            ..._activeRecords.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.sageTua, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.title,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.teksGelap,
                            ),
                          ),
                          Text(
                            'Waktu: ${rec.scheduledDate.hour.toString().padLeft(2, '0')}:${rec.scheduledDate.minute.toString().padLeft(2, '0')} WIB (${rec.scheduledDate.day}/${rec.scheduledDate.month}/${rec.scheduledDate.year})',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.teksGelap.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
