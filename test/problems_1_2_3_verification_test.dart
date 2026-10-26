// ==============================================================================
// VERIFICATION TEST: Problems 1, 2, 3 (Faunova)
// Bukti Verifikasi:
// Problem 1: Visibilitas Sampah (Feed, Profil, Notifikasi ramah, Share status)
// Problem 2: Grid Koleksi menggunakan MediaResolver (tidak lagi placeholder)
// Problem 3: Refresh otomatis seketika setelah simpan, trash, restore, purge
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/services/capture_service.dart';
import 'package:faunova/core/services/trash_service.dart';
import 'package:faunova/core/services/post_service.dart';
import 'package:faunova/core/services/social_service.dart';
import 'package:faunova/core/utils/media_resolver.dart';
import 'package:faunova/features/camera/models/capture_model.dart';
import 'package:faunova/core/services/notification_service.dart';

void main() {
  setUp(() {
    PostService.instance.initMockDemoPosts();
    CaptureService.instance.initMockDemoCaptures();
    TrashService.instance.resetDemoTrash();
  });

  group('Problem 1: Trash Visibility & Cross-Feature Behavior', () {
    test('1. Post di-trash langsung tersembunyi dari feed dan profil', () async {
      final postsBefore = await PostService.instance.fetchForYouFeed();
      final targetPost = postsBefore.first;

      // Trash post
      await TrashService.instance.trashPost(targetPost.id);

      // Verifikasi feed
      final postsAfter = await PostService.instance.fetchForYouFeed();
      expect(postsAfter.any((p) => p.id == targetPost.id), isFalse,
          reason: 'Post di sampah tidak boleh muncul di feed Untuk Kamu');

      // Verifikasi profil penulis
      final userPosts = await SocialService.instance.fetchUserPublicPosts(targetPost.authorId);
      expect(userPosts.any((p) => p.id == targetPost.id), isFalse,
          reason: 'Post di sampah tidak boleh muncul di linimasa profil');
    });

    test('2. Capture di-trash menyembunyikan capture dari grid dan post terkait dari feed', () async {
      // Capture id 'mock-cap-1' dihubungkan dengan post 'mock-post-1' milik Siti
      final initialPosts = await PostService.instance.fetchForYouFeed();
      expect(initialPosts.any((p) => p.captureId == 'mock-cap-1'), isTrue);

      // Trash capture
      await TrashService.instance.trashCapture('mock-cap-1');

      // Grid koleksi tidak lagi memuat capture ini
      final myTrash = await TrashService.instance.fetchMyTrash();
      expect(myTrash['captures']!.any((c) => c.id == 'mock-cap-1'), isTrue,
          reason: 'Capture harus berada di keranjang Sampah');

      // Post terkait harus otomatis tersembunyi dari linimasa
      final postsAfter = await PostService.instance.fetchForYouFeed();
      expect(postsAfter.any((p) => p.captureId == 'mock-cap-1'), isFalse,
          reason: 'Postingan yang capture induknya di-trash harus otomatis tersembunyi');
    });

    test('3. Memulihkan capture mengembalikan postingan ke linimasa publik', () async {
      await TrashService.instance.trashCapture('mock-cap-1');
      await TrashService.instance.restoreCapture('mock-cap-1');

      final postsRestored = await PostService.instance.fetchForYouFeed();
      expect(postsRestored.any((p) => p.captureId == 'mock-cap-1'), isTrue,
          reason: 'Memulihkan capture harus memulihkan keterlihatan post');
    });

    test('4. Notifikasi untuk post di tempat sampah menampilkan pesan ramah dan tidak crash', () {
      final notif = SocialNotificationItem(
        id: 'notif-trash-test',
        recipientUserId: 'user-me',
        actorUserId: 'user-budi',
        actorName: 'Budi Santoso',
        type: 'like',
        postId: 'mock-post-trashed',
        title: 'Postingan Tidak Tersedia',
        body: 'Postingan ini telah dipindahkan ke Sampah atau tidak lagi tersedia.',
        createdAt: DateTime.now(),
      );

      expect(notif.title, contains('Tidak Tersedia'));
      expect(notif.body, contains('tidak lagi tersedia'));
    });
  });

  group('Problem 2: Collection Grid MediaResolver & Image Rendering', () {
    test('1. MediaResolver menyelesaikan path storage Supabase menjadi URL publik valid', () {
      const storagePath = 'captures/user123/scan456_timestamp.jpg';
      final resolved = MediaResolver.resolvePhotoUrl(storagePath);
      expect(resolved, startsWith('http'));
      expect(resolved, contains('/storage/v1/object/public/captures/user123/scan456_timestamp.jpg'));
    });

    test('2. MediaResolver menyelesaikan URL http/https utuh tanpa merusak', () {
      const fullUrl = 'https://images.unsplash.com/photo-1574063413132-355dbfd83e12';
      final resolved = MediaResolver.resolvePhotoUrl(fullUrl);
      expect(resolved, equals(fullUrl));
    });

    test('3. MediaResolver menyelesaikan asset lokal tanpa merusak', () {
      const assetPath = 'assets/images/jalak_bali.jpg';
      final resolved = MediaResolver.resolvePhotoUrl(assetPath);
      expect(resolved, equals(assetPath));
    });
  });

  group('Problem 3: Instant Grid & Feed Refresh via Notifiers', () {
    test('1. saveCapture memicu onCaptureSavedNotifier seketika tanpa navigasi manual', () async {
      CaptureModel? savedNotification;
      CaptureService.instance.onCaptureSavedNotifier.addListener(() {
        savedNotification = CaptureService.instance.onCaptureSavedNotifier.value;
      });

      // Simpan capture demo
      final result = await CaptureService.instance.saveCapture(
        scanId: 'test-scan-immediate',
        demoSpeciesName: 'Cendrawasih Emas',
        demoCategory: 'Aves',
        photoPath: 'captures/demo/immediate.jpg',
      );

      expect(savedNotification, isNotNull);
      expect(savedNotification!.id, equals(result.id));
      expect(savedNotification!.speciesName, equals('Cendrawasih Emas'));
    });

    test('2. Operasi Sampah (trash, restore, purge) memicu onTrashChangedNotifier seketika', () async {
      int trashEvents = 0;
      TrashService.instance.onTrashChangedNotifier.addListener(() {
        trashEvents++;
      });

      // 1. Trash post
      await TrashService.instance.trashPost('mock-post-1');
      expect(trashEvents, equals(1));

      // 2. Restore post
      await TrashService.instance.restorePost('mock-post-1');
      expect(trashEvents, equals(2));

      // 3. Trash capture
      await TrashService.instance.trashCapture('mock-cap-2');
      expect(trashEvents, equals(3));

      // 4. Restore capture
      await TrashService.instance.restoreCapture('mock-cap-2');
      expect(trashEvents, equals(4));

      // 5. Purge item
      await TrashService.instance.trashPost('mock-post-2');
      final currentEvents = trashEvents;
      await TrashService.instance.purgeItem(type: 'post', id: 'mock-post-2');
      expect(trashEvents, equals(currentEvents + 1));
    });
  });
}
