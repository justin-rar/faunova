// ==============================================================================
// VERIFICATION TEST: Bug Fix — Like pada Profil Publik
// Memverifikasi bahwa tombol like di profil publik memanggil togglePostLike
// dengan optimistic update, bukan me-reload seluruh halaman.
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/services/post_service.dart';
import 'package:faunova/core/services/social_service.dart';
import 'package:faunova/core/services/trash_service.dart';
import 'package:faunova/core/services/notification_service.dart';

void main() {
  setUp(() {
    PostService.instance.initMockDemoPosts();
    SocialService.instance.initMockDemoSocial();
    TrashService.instance.resetDemoTrash();
    NotificationService.instance.clearNotificationQueues();
    NotificationService.instance.setMockCurrentUserId('user-viewer');
    PostService.instance.setMockCurrentUserId('user-viewer');
    SocialService.instance.setMockCurrentUserId('user-viewer');
  });

  group('Bug Fix: Like pada Profil Publik', () {
    test('togglePostLike mengubah isLikedByMe dan likesCount pada post demo', () async {
      // Ambil post Budi yang awalnya isLikedByMe = false
      final posts = PostService.instance.demoPosts;
      final jalakBaliPost = posts.firstWhere((p) => p.id == 'mock-post-1');
      expect(jalakBaliPost.isLikedByMe, isFalse);
      expect(jalakBaliPost.likesCount, equals(98));

      // Toggle like — harus mengubah state
      final result = await PostService.instance.togglePostLike(
        jalakBaliPost.id,
        targetAuthorId: jalakBaliPost.authorId,
        speciesName: jalakBaliPost.speciesName,
      );

      expect(result['is_liked'], isTrue);
      expect(result['likes_count'], equals(99));

      // Verifikasi di demoPosts juga berubah
      final updated = PostService.instance.demoPosts.firstWhere((p) => p.id == 'mock-post-1');
      expect(updated.isLikedByMe, isTrue);
      expect(updated.likesCount, equals(99));
    });

    test('togglePostLike unlike kembali menurunkan count', () async {
      // Post yang awalnya isLikedByMe = true
      final posts = PostService.instance.demoPosts;
      final elangPost = posts.firstWhere((p) => p.id == 'mock-post-1b');
      expect(elangPost.isLikedByMe, isTrue);
      expect(elangPost.likesCount, equals(73));

      // Toggle unlike
      final result = await PostService.instance.togglePostLike(
        elangPost.id,
        targetAuthorId: elangPost.authorId,
        speciesName: elangPost.speciesName,
      );

      expect(result['is_liked'], isFalse);
      expect(result['likes_count'], equals(72));
    });

    test('togglePostLike idempoten: like lalu unlike kembali ke semula', () async {
      final posts = PostService.instance.demoPosts;
      final post = posts.firstWhere((p) => p.id == 'mock-post-4');
      final originalLiked = post.isLikedByMe;
      final originalCount = post.likesCount;

      // Like
      await PostService.instance.togglePostLike(post.id);
      // Unlike
      await PostService.instance.togglePostLike(post.id);

      final restored = PostService.instance.demoPosts.firstWhere((p) => p.id == 'mock-post-4');
      expect(restored.isLikedByMe, equals(originalLiked));
      expect(restored.likesCount, equals(originalCount));
    });

    test('fetchUserPublicPosts mengembalikan post dengan ID yang benar untuk togglePostLike', () async {
      final userPosts = await SocialService.instance.fetchUserPublicPosts('user-budi');
      expect(userPosts.isNotEmpty, isTrue);

      // Setiap post milik Budi harus punya authorId = user-budi
      for (final p in userPosts) {
        expect(p.authorId, equals('user-budi'));
      }

      // Like post pertama harus sukses tanpa error
      final result = await PostService.instance.togglePostLike(
        userPosts.first.id,
        targetAuthorId: userPosts.first.authorId,
        speciesName: userPosts.first.speciesName,
      );
      expect(result['is_liked'], isNotNull);
      expect(result['likes_count'], isNotNull);
    });

    test('like post orang lain dari profil: notifikasi dikirim ke pemilik, bukan ke diri sendiri', () async {
      // Verifikasi bahwa like ke post user-budi mengirim notifikasi ke user-budi
      // (bukan ke user-viewer yang sedang login)
      final budiNotifsBefore = NotificationService.instance.fetchMyNotifications('user-budi');
      final countBefore = budiNotifsBefore.length;

      await PostService.instance.togglePostLike(
        'mock-post-1',
        targetAuthorId: 'user-budi',
        speciesName: 'Jalak Bali',
      );

      final budiNotifsAfter = NotificationService.instance.fetchMyNotifications('user-budi');
      expect(budiNotifsAfter.length, greaterThan(countBefore));
    });

    test('like post diri sendiri TIDAK membuat notifikasi', () async {
      PostService.instance.setMockCurrentUserId('user-budi');
      NotificationService.instance.setMockCurrentUserId('user-budi');

      final budiNotifsBefore = NotificationService.instance.fetchMyNotifications('user-budi');
      final countBefore = budiNotifsBefore.length;

      await PostService.instance.togglePostLike(
        'mock-post-1',
        targetAuthorId: 'user-budi',
        speciesName: 'Jalak Bali',
      );

      final budiNotifsAfter = NotificationService.instance.fetchMyNotifications('user-budi');
      expect(budiNotifsAfter.length, equals(countBefore));
    });
  });
}
