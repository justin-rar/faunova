import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/services/notification_service.dart';
import 'package:faunova/core/services/social_service.dart';
import 'package:faunova/core/services/post_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BUG 2: Notifikasi Aktivitas Sosial Follow dan Like', () {
    const actorUserId = 'actor-user-123';
    const recipientUserId = 'recipient-user-456';

    setUp(() async {
      await NotificationService.instance.init();
      await NotificationService.instance.cancelAll();
      NotificationService.instance.clearNotificationQueues();
    });

    test('SocialService.toggleFollow mengirim notifikasi follow khusus untuk akun penerima', () async {
      NotificationService.instance.setMockCurrentUserId(actorUserId);

      // Jalankan aksi follow ke penerima
      await SocialService.instance.toggleFollow(recipientUserId);

      // HP Pelaku TIDAK boleh menerima notifikasi
      final actorRecord = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialFollow);
      expect(actorRecord, isNull, reason: 'Pelaku tidak boleh menerima notifikasi untuk aksinya sendiri');

      // Penerima memiliki notifikasi tersimpan
      final recipientNotifs = NotificationService.instance.fetchMyNotifications(recipientUserId);
      expect(recipientNotifs, isNotEmpty);
      expect(recipientNotifs.first.type, equals('follow'));
      expect(recipientNotifs.first.recipientUserId, equals(recipientUserId));
      expect(recipientNotifs.first.actorUserId, equals(actorUserId));

      // Ketika penerima membuka app, notifikasi lokal terpicu
      await NotificationService.instance.deliverPendingNotificationsForUser(recipientUserId);
      final recipientRecord = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialFollow);
      expect(recipientRecord, isNotNull);
      expect(recipientRecord!.title, contains('Pengikut'));
    });

    test('PostService.togglePostLike mengirim notifikasi like khusus untuk pemilik postingan', () async {
      NotificationService.instance.setMockCurrentUserId(actorUserId);

      // Dapatkan post ID dari demo/feed
      final posts = await PostService.instance.fetchForYouFeed();
      final targetPost = posts.first;
      expect(targetPost.authorId, isNot(equals(actorUserId)));

      // Pastikan belum disukai
      if (targetPost.isLikedByMe) {
        await PostService.instance.togglePostLike(targetPost.id);
      }

      // Beri like
      await PostService.instance.togglePostLike(targetPost.id);

      // HP Pelaku TIDAK boleh menerima notifikasi
      final actorRecord = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialLike);
      expect(actorRecord, isNull, reason: 'Pelaku tidak boleh menerima notifikasi like untuk aksinya sendiri');

      // Pemilik postingan (penerima) memiliki notifikasi tersimpan
      final authorNotifs = NotificationService.instance.fetchMyNotifications(targetPost.authorId);
      expect(authorNotifs, isNotEmpty);
      expect(authorNotifs.first.type, equals('like'));
      expect(authorNotifs.first.recipientUserId, equals(targetPost.authorId));

      // Ketika pemilik post membuka app, notifikasi lokal terpicu
      await NotificationService.instance.deliverPendingNotificationsForUser(targetPost.authorId);
      final authorRecord = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialLike);
      expect(authorRecord, isNotNull);
      expect(authorRecord!.title, contains('Disukai'));
    });
  });
}
