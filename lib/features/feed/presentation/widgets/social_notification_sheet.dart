// ==============================================================================
// FAUNOVA WIDGET: SocialNotificationSheet
// Lembar Pusat Notifikasi Aktivitas Sosial (Follow, Like, Realtime)
// Sesuai Plan 5.9, Scope Tingkat 3 & AGENTS.md
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../profile/presentation/public_profile_page.dart';
import '../../../profile/presentation/widgets/notification_setting_sheet.dart';

class SocialNotificationSheet extends StatefulWidget {
  const SocialNotificationSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SocialNotificationSheet(),
    );
  }

  @override
  State<SocialNotificationSheet> createState() => _SocialNotificationSheetState();
}

class _SocialNotificationSheetState extends State<SocialNotificationSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  List<SocialNotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await NotificationService.instance.fetchServerNotifications();
      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      }
      // Tandai semua sebagai telah dibaca setelah ditampilkan
      await NotificationService.instance.markAllAsRead();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat notifikasi: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sageMuda,
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
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.sageTua,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pusat Notifikasi',
                        style: AppTypography.titleUi(
                          color: AppColors.teksGelap,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Aktivitas terbaru dari penjelajah satwa',
                        style: AppTypography.labelCaption(
                          color: AppColors.teksGelap.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Pengaturan Alarm & Pengingat',
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.sageTua,
                    size: 22,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    NotificationSettingSheet.show(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.sageMuda),

          // Konten Utama
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.sageTua,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.merahStatus,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: AppColors.teksGelap),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emas,
                  foregroundColor: AppColors.teksGelap,
                ),
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.sageMuda.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 38,
                  color: AppColors.sageTua,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Notifikasi',
                style: AppTypography.titleUi(
                  color: AppColors.teksGelap,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aktivitas saat penjelajah lain mengikuti Anda atau menyukai postingan satwa Anda akan langsung tampil seketika di sini.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(
                  color: AppColors.teksGelap.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.sageTua,
      backgroundColor: AppColors.gading,
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 72,
          color: Color(0xFFE5ECE2),
        ),
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final isFollow = notif.type == 'follow';
          return InkWell(
            onTap: () {
              if (notif.title.contains('Tidak Tersedia') || notif.body.contains('tidak lagi tersedia')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Postingan ini telah dipindahkan ke Sampah atau tidak lagi tersedia.'),
                    backgroundColor: AppColors.sageTua,
                  ),
                );
                return;
              }
              if (notif.actorUserId.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicProfilePage(
                      userId: notif.actorUserId,
                      initialAuthorName: notif.actorName,
                      initialAuthorUsername: notif.actorUsername,
                    ),
                  ),
                );
              }
            },
            child: Container(
              color: notif.isRead
                  ? Colors.transparent
                  : AppColors.sageMuda.withValues(alpha: 0.18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar dengan ikon tipe di sudut bawah
                  Stack(
                    children: [
                      AppAvatar(
                        avatarPath: notif.actorAvatar,
                        displayName: notif.actorName,
                        radius: 22,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isFollow ? AppColors.sageTua : AppColors.merahStatus,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Icon(
                            isFollow ? Icons.person_add_rounded : Icons.favorite_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Isi notifikasi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: AppTypography.bodyMedium(
                              color: AppColors.teksGelap,
                            ),
                            children: [
                              TextSpan(
                                text: notif.actorName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: isFollow
                                    ? ' mulai mengikuti linimasa satwa Anda.'
                                    : (notif.title.contains('Tidak Tersedia') || notif.body.contains('tidak lagi tersedia')
                                        ? ' menyukai postingan Anda (postingan kini di Sampah / tidak lagi tersedia).'
                                        : (notif.speciesName != null &&
                                                notif.speciesName!.isNotEmpty
                                            ? ' menyukai tangkapan ${notif.speciesName} Anda.'
                                            : ' menyukai postingan linimasa Anda.')),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimeAgo(notif.createdAt),
                          style: AppTypography.labelCaption(
                            color: AppColors.teksGelap.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Indikator belum dibaca (titik emas)
                  if (!notif.isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.emas,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
