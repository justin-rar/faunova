// ==============================================================================
// FAUNOVA SERVICE: TrashService
// Layanan pengelolaan Sampah (Soft Delete), Pemulihan, dan Purge Permanen
// Sesuai Plan 5.2, 5.3, 5.7, 5.9, Scope Tingkat 3 & Aturan Keras AGENTS.md
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../../features/feed/models/post_model.dart';
import '../../features/camera/models/capture_model.dart';
import 'post_service.dart';
import 'encrypted_storage_service.dart';

class TrashException implements Exception {
  final String message;
  final String code;

  const TrashException(this.message, {this.code = 'TRASH_ERROR'});

  @override
  String toString() => message;
}

class TrashedItemModel {
  final String id;
  final String type; // 'post' atau 'capture'
  final String? captureId;
  final String title;
  final String? subtitle;
  final String photoUrl;
  final DateTime trashedAt;
  final int daysLeft;
  final bool hasLinkedPost;

  const TrashedItemModel({
    required this.id,
    required this.type,
    this.captureId,
    required this.title,
    this.subtitle,
    required this.photoUrl,
    required this.trashedAt,
    required this.daysLeft,
    this.hasLinkedPost = false,
  });
}

class TrashService {
  static final TrashService instance = TrashService._internal();
  TrashService._internal();

  /// Notifier ketika ada aktivitas Sampah (trash, restore, purge)
  final ValueNotifier<int> onTrashChangedNotifier = ValueNotifier<int>(0);

  SupabaseClient? _getSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? _getCurrentUserId() {
    try {
      final client = _getSupabaseClient();
      return client?.auth.currentUser?.id ?? client?.auth.currentSession?.user.id;
    } catch (_) {
      return null;
    }
  }

  // Antrean memori untuk mode demo / testing
  final List<PostModel> _demoTrashedPosts = [];
  final List<CaptureModel> _demoTrashedCaptures = [];

  List<PostModel> get demoTrashedPosts => _demoTrashedPosts;
  List<CaptureModel> get demoTrashedCaptures => _demoTrashedCaptures;

  void resetDemoTrash() {
    _demoTrashedPosts.clear();
    _demoTrashedCaptures.clear();
  }

  /// Mengambil daftar seluruh item di Sampah milik pengguna yang aktif (< 30 hari)
  Future<Map<String, List<TrashedItemModel>>> fetchMyTrash() async {
    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || userId == null) {
      final now = DateTime.now();
      final posts = _demoTrashedPosts.where((p) {
        final daysDiff = now.difference(p.trashedAt ?? now).inDays;
        return daysDiff <= AppConfig.trashRetentionDays;
      }).map((p) {
        final daysLeft = (AppConfig.trashRetentionDays - now.difference(p.trashedAt ?? now).inDays).clamp(0, 30);
        return TrashedItemModel(
          id: p.id,
          type: 'post',
          captureId: p.captureId,
          title: p.speciesName,
          subtitle: p.caption,
          photoUrl: p.photoUrl,
          trashedAt: p.trashedAt ?? now,
          daysLeft: daysLeft,
        );
      }).toList();

      final captures = _demoTrashedCaptures.where((c) {
        final daysDiff = now.difference(c.trashedAt ?? now).inDays;
        return daysDiff <= AppConfig.trashRetentionDays && !c.isPurged;
      }).map((c) {
        final daysLeft = (AppConfig.trashRetentionDays - now.difference(c.trashedAt ?? now).inDays).clamp(0, 30);
        return TrashedItemModel(
          id: c.id,
          type: 'capture',
          title: c.speciesName,
          subtitle: c.category ?? 'Satwa Terverifikasi',
          photoUrl: c.photoObjectPath,
          trashedAt: c.trashedAt ?? now,
          daysLeft: daysLeft,
          hasLinkedPost: PostService.instance.demoPosts.any((p) => p.captureId == c.id),
        );
      }).toList();

      return {
        'posts': posts,
        'captures': captures,
      };
    }

    try {
      final response = await client.rpc(
        'get_my_trash',
        params: {'p_retention_days': AppConfig.trashRetentionDays},
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(response as Map);
      final rawPosts = (data['posts'] as List<dynamic>?) ?? [];
      final rawCaptures = (data['captures'] as List<dynamic>?) ?? [];

      final posts = rawPosts.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return TrashedItemModel(
          id: map['post_id'].toString(),
          type: 'post',
          captureId: map['capture_id']?.toString(),
          title: map['species_name']?.toString() ?? 'Postingan Satwa',
          subtitle: map['caption']?.toString() ?? '',
          photoUrl: map['photo_object_path']?.toString() ?? '',
          trashedAt: DateTime.tryParse(map['trashed_at'].toString()) ?? DateTime.now(),
          daysLeft: (map['days_left'] as num?)?.toInt() ?? 30,
        );
      }).toList();

      final captures = rawCaptures.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return TrashedItemModel(
          id: map['capture_id'].toString(),
          type: 'capture',
          title: map['species_name']?.toString() ?? 'Koleksi Satwa',
          subtitle: map['category']?.toString() ?? 'Satwa Terverifikasi',
          photoUrl: map['photo_object_path']?.toString() ?? '',
          trashedAt: DateTime.tryParse(map['trashed_at'].toString()) ?? DateTime.now(),
          daysLeft: (map['days_left'] as num?)?.toInt() ?? 30,
          hasLinkedPost: map['has_linked_post'] == true,
        );
      }).toList();

      return {
        'posts': posts,
        'captures': captures,
      };
    } catch (e) {
      debugPrint('TrashService fetchMyTrash error: $e');
      throw TrashException('Gagal memuat item Sampah: ${e.toString()}');
    }
  }

  /// Memindahkan postingan linimasa ke Sampah
  Future<void> trashPost(String postId) async {
    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || userId == null) {
      // Periksa apakah sudah ada di trash (idempoten)
      final alreadyInTrash = _demoTrashedPosts.firstWhere((p) => p.id == postId, orElse: () => PostModel(
        id: '',
        captureId: '',
        caption: '',
        locationVisibility: '',
        createdAt: DateTime.now(),
        speciesName: '',
        photoUrl: '',
        blockSeq: 0,
        blockHash: '',
        photoSha256: '',
        authorId: '',
        authorName: '',
        authorUsername: '',
      ));
      if (alreadyInTrash.id.isNotEmpty) {
        // Idempoten: Jangan reset trashed_at yang ada
        return;
      }

      final idx = PostService.instance.demoPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final post = PostService.instance.demoPosts[idx];
        if (post.isDeleted) {
          throw const TrashException('Postingan telah dimoderasi dan tidak dapat dipindahkan ke Sampah.', code: 'MODERATED');
        }
        final trashedPost = post.copyWith(trashedAt: post.trashedAt ?? DateTime.now());
        PostService.instance.removeDemoPost(postId);
        _demoTrashedPosts.add(trashedPost);
        onTrashChangedNotifier.value++;
      }
      return;
    }

    try {
      final response = await client.rpc(
        'trash_post',
        params: {'p_post_id': postId},
      );

      // Sinkronisasi memori lokal demoPosts
      PostService.instance.removeDemoPost(postId);
      onTrashChangedNotifier.value++;
      debugPrint('TrashService trashPost berhasil: $response');
    } on PostgrestException catch (e) {
      debugPrint('TrashService trashPost PostgrestException: ${e.message} (${e.code})');
      throw TrashException(e.message, code: e.code ?? 'TRASH_POST_ERROR');
    } catch (e) {
      if (e is TrashException) rethrow;
      throw TrashException('Gagal memindahkan postingan ke Sampah: ${e.toString()}');
    }
  }

  /// Memulihkan postingan dari Sampah ke linimasa publik
  Future<void> restorePost(String postId) async {
    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || userId == null) {
      final idx = _demoTrashedPosts.indexWhere((p) => p.id == postId);
      if (idx == -1) {
        throw const TrashException('Postingan tidak berada di Sampah.', code: 'NOT_IN_TRASH');
      }

      final post = _demoTrashedPosts[idx];

      // Batas retensi 30 hari
      if (post.trashedAt != null && DateTime.now().difference(post.trashedAt!).inDays > AppConfig.trashRetentionDays) {
        throw const TrashException('Masa retensi postingan telah kedaluwarsa (lebih dari 30 hari).', code: 'EXPIRED');
      }

      // Validasi: Jika koleksi induk dipurge, tolak restore
      final isCapPurged = _demoTrashedCaptures.any((c) => c.id == post.captureId && c.isPurged);
      if (isCapPurged) {
        throw const TrashException('Koleksi terkait telah dipurge permanen.', code: 'CAPTURE_PURGED');
      }

      // Validasi: Jika koleksi induk di sampah, tolak restore
      final isCapTrashed = _demoTrashedCaptures.any((c) => c.id == post.captureId && !c.isPurged);
      if (isCapTrashed) {
        throw const TrashException(
          'Koleksi terkait masih berada di Sampah. Pulihkan koleksi terlebih dahulu.',
          code: 'CAPTURE_IN_TRASH',
        );
      }

      final restored = post.copyWith(clearTrashedAt: true);
      _demoTrashedPosts.removeAt(idx);
      PostService.instance.insertDemoPost(restored);
      onTrashChangedNotifier.value++;
      return;
    }

    try {
      final response = await client.rpc(
        'restore_post',
        params: {'p_post_id': postId},
      );
      onTrashChangedNotifier.value++;
      debugPrint('TrashService restorePost berhasil: $response');
    } on PostgrestException catch (e) {
      debugPrint('TrashService restorePost PostgrestException: ${e.message} (${e.code})');
      throw TrashException(e.message, code: e.code ?? 'RESTORE_POST_ERROR');
    } catch (e) {
      if (e is TrashException) rethrow;
      throw TrashException('Gagal memulihkan postingan: ${e.toString()}');
    }
  }

  /// Memindahkan koleksi ke Sampah (otomatis menyembunyikan post terkait via filter capture)
  Future<void> trashCapture(String captureId) async {
    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || userId == null) {
      if (_demoTrashedCaptures.any((c) => c.id == captureId)) {
        // Idempoten
        return;
      }
      final effectiveUser = userId ?? '00000000-0000-0000-0000-000000000001';
      final existingCaptures = EncryptedStorageService.instance.getUserCaptures(effectiveUser);
      final idx = existingCaptures.indexWhere((c) => c.id == captureId);
      if (idx != -1) {
        final cap = existingCaptures[idx];
        if (cap.isPurged) {
          throw const TrashException('Koleksi telah dipurge permanen.', code: 'ALREADY_PURGED');
        }
        final trashedCap = cap.copyWith(trashedAt: cap.trashedAt ?? DateTime.now());
        final updatedCaptures = existingCaptures.where((c) => c.id != captureId).toList();
        await EncryptedStorageService.instance.saveUserCaptures(effectiveUser, updatedCaptures);
        _demoTrashedCaptures.add(trashedCap);
        onTrashChangedNotifier.value++;
      }
      return;
    }

    try {
      final response = await client.rpc(
        'trash_capture',
        params: {'p_capture_id': captureId},
      );

      // Invalidate cache lokal Hive
      try {
        await EncryptedStorageService.instance.clearUserCaptures(userId);
      } catch (_) {}

      onTrashChangedNotifier.value++;
      debugPrint('TrashService trashCapture berhasil: $response');
    } on PostgrestException catch (e) {
      debugPrint('TrashService trashCapture PostgrestException: ${e.message} (${e.code})');
      throw TrashException(e.message, code: e.code ?? 'TRASH_CAPTURE_ERROR');
    } catch (e) {
      if (e is TrashException) rethrow;
      throw TrashException('Gagal memindahkan koleksi ke Sampah: ${e.toString()}');
    }
  }

  /// Memulihkan koleksi dari Sampah (kembali ke tab Koleksi)
  Future<void> restoreCapture(String captureId) async {
    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || userId == null) {
      final effectiveUser = userId ?? '00000000-0000-0000-0000-000000000001';
      final idx = _demoTrashedCaptures.indexWhere((c) => c.id == captureId);
      if (idx == -1) {
        throw const TrashException('Koleksi tidak berada di Sampah.', code: 'NOT_IN_TRASH');
      }

      final cap = _demoTrashedCaptures[idx];
      if (cap.isPurged) {
        throw const TrashException('Koleksi telah dipurge permanen.', code: 'ALREADY_PURGED');
      }
      if (cap.trashedAt != null && DateTime.now().difference(cap.trashedAt!).inDays > AppConfig.trashRetentionDays) {
        throw const TrashException('Masa retensi koleksi telah kedaluwarsa (lebih dari 30 hari).', code: 'EXPIRED');
      }

      final restored = cap.copyWith(clearTrashedAt: true);
      _demoTrashedCaptures.removeAt(idx);
      final existing = EncryptedStorageService.instance.getUserCaptures(effectiveUser);
      final updated = [restored, ...existing.where((c) => c.id != captureId)];
      await EncryptedStorageService.instance.saveUserCaptures(effectiveUser, updated);
      onTrashChangedNotifier.value++;
      return;
    }

    try {
      final response = await client.rpc(
        'restore_capture',
        params: {'p_capture_id': captureId},
      );

      // Invalidate cache lokal Hive
      try {
        await EncryptedStorageService.instance.clearUserCaptures(userId);
      } catch (_) {}

      onTrashChangedNotifier.value++;
      debugPrint('TrashService restoreCapture berhasil: $response');
    } on PostgrestException catch (e) {
      debugPrint('TrashService restoreCapture PostgrestException: ${e.message} (${e.code})');
      throw TrashException(e.message, code: e.code ?? 'RESTORE_CAPTURE_ERROR');
    } catch (e) {
      if (e is TrashException) rethrow;
      throw TrashException('Gagal memulihkan koleksi: ${e.toString()}');
    }
  }

  /// Purge permanen satu item dari tempat sampah:
  /// Urutan aman untuk capture:
  /// 1. Hapus berkas foto dari Supabase Storage terlebih dahulu.
  /// 2. Jalankan RPC purge_trash_item (hard-delete post cascade, lalu tombstone DB row capture).
  Future<void> purgeItem({
    required String type, // 'post' atau 'capture'
    required String id,
    String? photoObjectPath,
  }) async {
    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || userId == null) {
      final effectiveUser = userId ?? '00000000-0000-0000-0000-000000000001';
      if (type == 'post') {
        final idx = _demoTrashedPosts.indexWhere((p) => p.id == id);
        if (idx == -1) {
          final inActive = PostService.instance.demoPosts.any((p) => p.id == id);
          if (inActive) {
            throw const TrashException('Item tidak berada di Sampah (hanya item di Sampah yang dapat di-purge).', code: 'NOT_IN_TRASH');
          }
          // Idempoten
          return;
        }
        final p = _demoTrashedPosts[idx];
        if (p.trashedAt == null) {
          throw const TrashException('Item tidak berada di Sampah (hanya item di Sampah yang dapat di-purge).', code: 'NOT_IN_TRASH');
        }
        _demoTrashedPosts.removeAt(idx);
        PostService.instance.removeDemoPost(id);
      } else {
        final idx = _demoTrashedCaptures.indexWhere((c) => c.id == id);
        if (idx == -1) {
          final inActive = EncryptedStorageService.instance.getUserCaptures(effectiveUser).any((c) => c.id == id);
          if (inActive) {
            throw const TrashException('Item tidak berada di Sampah (hanya item di Sampah yang dapat di-purge).', code: 'NOT_IN_TRASH');
          }
          // Idempoten
          return;
        }
        final cap = _demoTrashedCaptures[idx];
        if (cap.isPurged) {
          // Idempoten
          return;
        }
        if (cap.trashedAt == null) {
          throw const TrashException('Item tidak berada di Sampah (hanya item di Sampah yang dapat di-purge).', code: 'NOT_IN_TRASH');
        }
        // Tombstone
        _demoTrashedCaptures[idx] = cap.copyWith(
          purgedAt: DateTime.now(),
          speciesName: '[Observasi Dipurge]',
          photoObjectPath: 'purged',
          clearCategory: true,
          clearDescription: true,
        );
        // Hapus post terkait
        _demoTrashedPosts.removeWhere((p) => p.captureId == id);
        PostService.instance.removeDemoPostsByCaptureId(id);
        try {
          await EncryptedStorageService.instance.clearUserCaptures(effectiveUser);
        } catch (_) {}
        onTrashChangedNotifier.value++;
      }
      return;
    }

    // 1. Jika bertipe capture dan memiliki file foto di storage, hapus file storage terlebih dahulu
    if (type == 'capture' && photoObjectPath != null && photoObjectPath.isNotEmpty && photoObjectPath != 'purged') {
      try {
        await client.storage.from('captures').remove([photoObjectPath]);
        debugPrint('TrashService: Foto storage berhasil dihapus: $photoObjectPath');
      } catch (e) {
        debugPrint('TrashService: Catatan penghapusan storage (melanjutkan): $e');
      }
    }

    // 2. Jalankan RPC purge_trash_item di database
    try {
      final response = await client.rpc(
        'purge_trash_item',
        params: {
          'p_type': type,
          'p_id': id,
        },
      );
      debugPrint('TrashService purgeItem berhasil: $response');

      // 3. Bersihkan cache lokal
      if (type == 'post') {
        PostService.instance.removeDemoPost(id);
      } else {
        PostService.instance.removeDemoPostsByCaptureId(id);
        try {
          EncryptedStorageService.instance.clearUserCaptures(userId);
        } catch (_) {}
      }
      onTrashChangedNotifier.value++;
    } on PostgrestException catch (e) {
      debugPrint('TrashService purgeItem PostgrestException: ${e.message} (${e.code})');
      throw TrashException(e.message, code: e.code ?? 'PURGE_ITEM_ERROR');
    } catch (e) {
      if (e is TrashException) rethrow;
      throw TrashException('Gagal menghapus item permanen: ${e.toString()}');
    }
  }

  /// Lazy Purge: Memeriksa dan membersihkan item yang telah kedaluwarsa (> 30 hari di Sampah)
  Future<void> runLazyPurge() async {
    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || userId == null) return;

    try {
      final response = await client.rpc(
        'get_expired_trash',
        params: {'p_retention_days': AppConfig.trashRetentionDays},
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(response as Map);
      final expiredPosts = (data['posts'] as List<dynamic>?) ?? [];
      final expiredCaptures = (data['captures'] as List<dynamic>?) ?? [];

      // Purge capture kedaluwarsa
      for (final raw in expiredCaptures) {
        final map = Map<String, dynamic>.from(raw as Map);
        final capId = map['id']?.toString();
        final photoPath = map['photo_object_path']?.toString();
        if (capId != null) {
          await purgeItem(type: 'capture', id: capId, photoObjectPath: photoPath);
        }
      }

      // Purge post kedaluwarsa
      for (final raw in expiredPosts) {
        final map = Map<String, dynamic>.from(raw as Map);
        final postId = map['id']?.toString();
        if (postId != null) {
          await purgeItem(type: 'post', id: postId);
        }
      }
    } catch (e) {
      debugPrint('TrashService runLazyPurge note (abaikan jika offline): $e');
    }
  }
}
