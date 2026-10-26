// ==============================================================================
// FAUNOVA PAGE: TrashPage
// Layanan antarmuka tempat sampah untuk pemulihan dan penghapusan permanen
// Sesuai Plan 5.2, 5.3, 5.7, 5.9, Scope Tingkat 3 & Aturan Keras AGENTS.md
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/trash_service.dart';
import '../../../core/utils/media_resolver.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TrashPage()),
    );
  }

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<TrashedItemModel> _posts = [];
  List<TrashedItemModel> _captures = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrash(runLazyPurgeFirst: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrash({bool runLazyPurgeFirst = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (runLazyPurgeFirst) {
        await TrashService.instance.runLazyPurge();
      }
      final result = await TrashService.instance.fetchMyTrash();
      if (mounted) {
        setState(() {
          _posts = List<TrashedItemModel>.from(result['posts'] ?? []);
          _captures = List<TrashedItemModel>.from(result['captures'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRestore(TrashedItemModel item) async {
    try {
      if (item.type == 'post') {
        await TrashService.instance.restorePost(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Postingan berhasil dipulihkan ke linimasa publik!'),
              backgroundColor: AppColors.sageTua,
            ),
          );
        }
      } else {
        await TrashService.instance.restoreCapture(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Koleksi satwa berhasil dipulihkan!'),
              backgroundColor: AppColors.sageTua,
            ),
          );
        }
      }
      if (mounted) {
        setState(() {
          _posts = _posts.where((p) => p.id != item.id).toList();
          _captures = _captures.where((c) => c.id != item.id).toList();
        });
      }
      _loadTrash();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteNow(TrashedItemModel item) async {
    final isCapture = item.type == 'capture';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.gading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.merahStatus, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hapus Permanen?',
                style: TextStyle(
                  color: AppColors.teksGelap,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isCapture
              ? 'Foto dan rincian observasi akan dihapus permanen dari penyimpanan. '
                'Catatan kriptografi blok (hash SHA-256) tetap disimpan sebagai tombstone untuk menjaga integritas rantai kanonis koleksi.'
              : 'Postingan linimasa dan seluruh data suka terkait akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.',
          style: AppTypography.bodyDefault(color: AppColors.teksGelap),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: AppTypography.labelProminent(color: AppColors.teksGelap),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merahStatus,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Hapus Sekarang',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TrashService.instance.purgeItem(
          type: item.type,
          id: item.id,
          photoObjectPath: item.photoUrl,
        );
        if (mounted) {
          setState(() {
            _posts = _posts.where((p) => p.id != item.id).toList();
            _captures = _captures.where((c) => c.id != item.id).toList();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item berhasil dihapus secara permanen.'),
              backgroundColor: AppColors.sageTua,
            ),
          );
        }
        _loadTrash();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.merahStatus,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gading,
      appBar: AppBar(
        backgroundColor: AppColors.sageTua,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksPutih),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tempat Sampah',
          style: TextStyle(
            color: AppColors.teksPutih,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.emas,
          indicatorWeight: 3,
          labelColor: AppColors.teksPutih,
          unselectedLabelColor: AppColors.teksPutih.withValues(alpha: 0.65),
          tabs: [
            Tab(text: 'Postingan (${_posts.length})'),
            Tab(text: 'Koleksi Satwa (${_captures.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner Info Retensi 30 Hari
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.sageMuda.withValues(alpha: 0.35),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.sageTua),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Item disimpan selama ${AppConfig.trashRetentionDays} hari sebelum dihapus permanen.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.teksGelap,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Konten Tab
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sageTua),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.merahStatus, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.teksGelap),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadTrash(runLazyPurgeFirst: false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.sageTua,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Coba Lagi', style: TextStyle(color: AppColors.teksPutih)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildItemList(_posts, isPostTab: true),
                          _buildItemList(_captures, isPostTab: false),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(List<TrashedItemModel> items, {required bool isPostTab}) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.sageMuda.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 48,
                  color: AppColors.sageTua,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isPostTab ? 'Tidak ada postingan di Sampah' : 'Tidak ada koleksi di Sampah',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.teksGelap,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Item yang dipindahkan ke Sampah akan tampil di sini selama ${AppConfig.trashRetentionDays} hari.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.teksGelap.withValues(alpha: 0.7),
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
      onRefresh: () => _loadTrash(runLazyPurgeFirst: false),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final resolvedPhoto = MediaResolver.resolvePhotoUrl(item.photoUrl, speciesName: item.title);
          Widget photoWidget;
          if (resolvedPhoto.startsWith('http://') || resolvedPhoto.startsWith('https://')) {
            photoWidget = Image.network(
              resolvedPhoto,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.pets_rounded,
                color: AppColors.sageTua,
              ),
            );
          } else if (resolvedPhoto.startsWith('assets/')) {
            photoWidget = Image.asset(resolvedPhoto, fit: BoxFit.cover);
          } else if (resolvedPhoto.isNotEmpty && File(resolvedPhoto).existsSync()) {
            photoWidget = Image.file(File(resolvedPhoto), fit: BoxFit.cover);
          } else {
            photoWidget = const Icon(Icons.pets_rounded, color: AppColors.sageTua);
          }

          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.sageMuda, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail Foto
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: AppColors.sageMuda.withValues(alpha: 0.3),
                          child: photoWidget,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info Satwa & Waktu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.teksGelap,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                item.subtitle!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.teksGelap.withValues(alpha: 0.75),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),

                            // Chip Sisa Hari
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: item.daysLeft <= 3
                                    ? AppColors.merahStatus.withValues(alpha: 0.12)
                                    : AppColors.emas.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: item.daysLeft <= 3 ? AppColors.merahStatus : AppColors.emasTua,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sisa ${item.daysLeft} hari',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: item.daysLeft <= 3 ? AppColors.merahStatus : AppColors.emasTua,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.sageMuda),
                  const SizedBox(height: 8),

                  // Tombol Aksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Tombol Hapus Sekarang
                      TextButton.icon(
                        onPressed: () => _handleDeleteNow(item),
                        icon: const Icon(Icons.delete_forever_rounded, size: 16, color: AppColors.merahStatus),
                        label: const Text(
                          'Hapus Sekarang',
                          style: TextStyle(fontSize: 12, color: AppColors.merahStatus, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tombol Pulihkan
                      ElevatedButton.icon(
                        onPressed: () => _handleRestore(item),
                        icon: const Icon(Icons.restore_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Pulihkan',
                          style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sageTua,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
