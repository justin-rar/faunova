import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/services/notification_service.dart';
import 'package:faunova/core/services/social_service.dart';
import 'package:faunova/core/services/post_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MASALAH B VERIFIKASI: Notifikasi Follow/Like dengan 2 Akun (Pelaku vs Penerima)', () {
    const actorUserId = '3c0ef0d9-d475-4ddf-b031-dafa5508c5e6'; // Akun A (wowoktt / Aniat)
    const recipientUserId = '6505f051-fb02-4cb6-9439-8f3933c8c041'; // Akun B (badaks / watashi)

    setUp(() async {
      await NotificationService.instance.init();
      await NotificationService.instance.cancelAll();
      NotificationService.instance.clearNotificationQueues();
    });

    test('1. Simulasi Akun A (Pelaku) Follow Akun B: Notifikasi TIDAK muncul di HP Pelaku', () async {
      // Simulasikan perangkat sedang login sebagai Akun A (Pelaku)
      NotificationService.instance.setMockCurrentUserId(actorUserId);

      // Akun A menekan tombol "Ikuti" untuk akun B
      await SocialService.instance.toggleFollow(recipientUserId);

      // Verifikasi di HP Akun A (Pelaku): Notifikasi lokal HARUS kosong (tidak boleh muncul di HP pelaku)
      final recordOnActorDevice = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialFollow);
      expect(recordOnActorDevice, isNull,
          reason: 'ATURAN KERAS: Notifikasi follow TIDAK BOLEH muncul di perangkat pelaku!');
      debugPrint('[LOG PERANGKAT AKUN A - PELAKU]: Status notifikasi lokal = NULL (Aman, tidak ada notifikasi keliru)');

      // Verifikasi di Antrean/Database Akun B (Penerima): Notifikasi follow TERSIMPAN untuk Akun B
      final notifsForRecipient = NotificationService.instance.fetchMyNotifications(recipientUserId);
      expect(notifsForRecipient, isNotEmpty,
          reason: 'Notifikasi follow harus tersimpan untuk akun penerima (Akun B)');
      expect(notifsForRecipient.first.recipientUserId, equals(recipientUserId));
      expect(notifsForRecipient.first.actorUserId, equals(actorUserId));
      expect(notifsForRecipient.first.type, equals('follow'));
      debugPrint('[LOG PERANGKAT AKUN B - PENERIMA]: Notifikasi masuk: '
          'Judul="${notifsForRecipient.first.title}", Penerima=${notifsForRecipient.first.recipientUserId}, Pengirim=${notifsForRecipient.first.actorUserId}');

      // Verifikasi query filter untuk Akun A: Akun A TIDAK memiliki notifikasi follow ini
      final notifsForActor = NotificationService.instance.fetchMyNotifications(actorUserId);
      expect(notifsForActor, isEmpty,
          reason: 'Query notifikasi Akun A tidak boleh mengembalikan notifikasi di mana Akun A adalah pelaku');
    });

    test('2. Simulasi Akun A (Pelaku) Like Postingan Akun B: Notifikasi jatuh ke Akun B, BUKAN Akun A', () async {
      // Simulasikan perangkat sedang login sebagai Akun A
      NotificationService.instance.setMockCurrentUserId(actorUserId);

      // Ambil postingan yang dibuat oleh Akun B
      final posts = await PostService.instance.fetchForYouFeed();
      final targetPost = posts.first; // Postingan milik akun lain

      // Pastikan target post bukan milik actorUserId
      expect(targetPost.authorId, isNot(equals(actorUserId)));

      // Akun A memberi Like pada postingan tersebut
      if (targetPost.isLikedByMe) {
        await PostService.instance.togglePostLike(targetPost.id);
      }
      await PostService.instance.togglePostLike(targetPost.id);

      // Verifikasi di HP Akun A (Pelaku): Notifikasi lokal like HARUS NULL
      final recordOnActorDevice = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialLike);
      expect(recordOnActorDevice, isNull,
          reason: 'ATURAN KERAS: Notifikasi like TIDAK BOLEH muncul di perangkat pelaku!');
      debugPrint('[LOG PERANGKAT AKUN A - PELAKU]: Status notifikasi like lokal = NULL (Aman)');

      // Verifikasi di Akun B (Author / Penerima): Notifikasi like berhasil diterima
      final notifsForAuthor = NotificationService.instance.fetchMyNotifications(targetPost.authorId);
      expect(notifsForAuthor, isNotEmpty,
          reason: 'Notifikasi like harus tersimpan untuk pemilik postingan');
      expect(notifsForAuthor.first.type, equals('like'));
      expect(notifsForAuthor.first.recipientUserId, equals(targetPost.authorId));
      expect(notifsForAuthor.first.actorUserId, equals(actorUserId));
      debugPrint('[LOG PERANGKAT AKUN B - PENERIMA]: Notifikasi like masuk: '
          'Judul="${notifsForAuthor.first.title}", Penerima=${notifsForAuthor.first.recipientUserId}');
    });

    test('3. Simulasi Like / Follow ke Diri Sendiri: Tidak ada notifikasi yang dibuat sama sekali', () async {
      // Simulasikan Akun A menyukai postingannya sendiri (actor == recipient)
      NotificationService.instance.setMockCurrentUserId(actorUserId);

      await NotificationService.instance.dispatchSocialNotification(
        recipientUserId: actorUserId,
        actorUserId: actorUserId,
        actorName: 'Aniat',
        type: 'like',
      );

      // Verifikasi: Tidak ada notifikasi yang masuk ke antrean maupun layar
      final notifs = NotificationService.instance.fetchMyNotifications(actorUserId);
      expect(notifs, isEmpty, reason: 'Like/follow ke diri sendiri tidak boleh membuat notifikasi');
      expect(NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialLike), isNull);
      debugPrint('[LOG UJI CEGAH SELF-NOTIFICATION]: Notifikasi aksi diri sendiri berhasil diblokir total.');
    });

    test('4. Simulasi Akun B (Penerima) membuka aplikasi: Notifikasi lokal terpicu di HP Akun B', () async {
      // Simulasikan Akun B sedang login di HP miliknya
      NotificationService.instance.setMockCurrentUserId(recipientUserId);

      // Kirim notifikasi dari Akun A ke Akun B
      await NotificationService.instance.dispatchSocialNotification(
        recipientUserId: recipientUserId,
        actorUserId: actorUserId,
        actorName: 'Aniat',
        type: 'follow',
      );

      // Di HP Akun B, notifikasi lokal harus terpicu saat deliverPendingNotificationsForUser
      await NotificationService.instance.deliverPendingNotificationsForUser(recipientUserId);

      final recordOnRecipientDevice = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialFollow);
      expect(recordOnRecipientDevice, isNotNull,
          reason: 'Notifikasi lokal HARUS muncul di perangkat penerima (Akun B)');
      expect(recordOnRecipientDevice!.title, contains('Pengikut Baru'));
      debugPrint('[LOG PENERIMAAN HP AKUN B]: Notifikasi lokal berhasil berdering di HP Akun B: "${recordOnRecipientDevice.title}"');
    });
  });
}
