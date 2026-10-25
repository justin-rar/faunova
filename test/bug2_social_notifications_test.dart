import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/services/notification_service.dart';
import 'package:faunova/core/services/social_service.dart';
import 'package:faunova/core/services/post_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BUG 2 REPRODUCE: Notifikasi Follow dan Like Belum Terpicu', () {
    setUp(() async {
      await NotificationService.instance.init();
      await NotificationService.instance.cancelAll();
    });

    test('Reproduksi: SocialService.toggleFollow harus memicu notifikasi follow', () async {
      // Sebelum aksi, belum ada notifikasi follow
      final initialRecord = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialFollow);
      expect(initialRecord, isNull, reason: 'Belum ada notifikasi follow sebelum toggle');

      // Jalankan aksi follow
      const targetUserId = 'target-user-uuid-123';
      await SocialService.instance.toggleFollow(targetUserId);

      // Verifikasi apakah notifikasi follow muncul
      final afterRecord = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialFollow);
      expect(afterRecord, isNotNull, reason: 'Notifikasi follow harus muncul setelah akun di-follow');
      expect(afterRecord!.title, contains('Pengikut'));
    });

    test('Reproduksi: PostService.togglePostLike harus memicu notifikasi like', () async {
      // Sebelum aksi, belum ada notifikasi like
      final initialRecord = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialLike);
      expect(initialRecord, isNull, reason: 'Belum ada notifikasi like sebelum toggle');

      // Dapatkan post ID dari demo/feed
      final posts = await PostService.instance.fetchForYouFeed();
      final targetPost = posts.first;

      // Pastikan belum disukai
      if (targetPost.isLikedByMe) {
        await PostService.instance.togglePostLike(targetPost.id);
      }

      // Beri like
      await PostService.instance.togglePostLike(targetPost.id);

      // Verifikasi apakah notifikasi like muncul
      final afterRecord = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialLike);
      expect(afterRecord, isNotNull, reason: 'Notifikasi like harus muncul setelah postingan disukai');
      expect(afterRecord!.title, contains('Disukai'));
    });
  });
}
