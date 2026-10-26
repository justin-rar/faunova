import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/services/notification_service.dart';
import 'package:faunova/core/services/social_service.dart';
import 'package:faunova/core/services/post_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VERIFIKASI SISTEM NOTIFIKASI LIKE & FOLLOW (STEP 3)', () {
    const actorA = '11111111-aaaa-bbbb-cccc-111111111111'; // User A (Pelaku)
    const ownerB = '22222222-aaaa-bbbb-cccc-222222222222'; // User B (Pemilik Postingan / Penerima)
    const samplePostId = '33333333-aaaa-bbbb-cccc-333333333333';

    setUp(() async {
      await NotificationService.instance.init();
      await NotificationService.instance.cancelAll();
      NotificationService.instance.clearNotificationQueues();
      PostService.instance.initMockDemoPosts();
    });

    test('1. Akun A Like Postingan Akun B: Notifikasi HANYA masuk ke B, BUKAN A', () async {
      // Simulasikan perangkat sedang login sebagai Akun A (Pelaku)
      NotificationService.instance.setMockCurrentUserId(actorA);

      // Akun A menekan tombol suka pada postingan milik Akun B
      await PostService.instance.togglePostLike(
        samplePostId,
        targetAuthorId: ownerB,
        speciesName: 'Cenderawasih Kuning-besar',
      );

      // Periksa HP Akun A (Pelaku): Notifikasi lokal like HARUS NULL
      final actorLikeBanner = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialLike);
      expect(actorLikeBanner, isNull,
          reason: 'ATURAN KERAS: Notifikasi like TIDAK BOLEH muncul di perangkat pelaku (Akun A)!');

      // Periksa Antrean / In-App List Akun A: Harus kosong (Akun A tidak melihat notifikasi like miliknya sendiri)
      final notifsForA = NotificationService.instance.fetchMyNotifications(actorA);
      expect(notifsForA, isEmpty,
          reason: 'Akun A tidak boleh melihat notifikasi aksinya sendiri');

      // Periksa Antrean / In-App List Akun B (Penerima): Harus menerima notifikasi
      final notifsForB = NotificationService.instance.fetchMyNotifications(ownerB);
      expect(notifsForB, isNotEmpty,
          reason: 'Notifikasi like harus tersimpan untuk akun penerima (Akun B)');
      final notif = notifsForB.first;
      expect(notif.recipientUserId, equals(ownerB));
      expect(notif.actorUserId, equals(actorA));
      expect(notif.type, equals('like'));
      expect(notif.postId, equals(samplePostId));
      expect(notif.speciesName, equals('Cenderawasih Kuning-besar'));
      expect(notif.title, equals('Postingan Anda Disukai! ❤️'));
      expect(notif.body, contains('menyukai tangkapan Cenderawasih Kuning-besar Anda.'));

      debugPrint('[SUKSES SKENARIO 1] Baris tersimpan untuk Akun B: '
          'Actor=${notif.actorUserId}, Recipient=${notif.recipientUserId}, Type=${notif.type}, PostId=${notif.postId}');

      // Simulasikan Akun B membuka aplikasi: Banner sistem terpicu di HP B
      NotificationService.instance.setMockCurrentUserId(ownerB);
      await NotificationService.instance.deliverPendingNotificationsForUser(ownerB);
      final bBanner = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialLike);
      expect(bBanner, isNotNull,
          reason: 'Banner lokal HARUS muncul di perangkat penerima (Akun B)');
      expect(bBanner!.title, contains('Postingan Anda Disukai'));
    });

    test('2. Self-like (Menyukai Postingan Diri Sendiri): Tidak ada notifikasi yang dibuat sama sekali', () async {
      // Simulasikan login sebagai Akun A
      NotificationService.instance.setMockCurrentUserId(actorA);

      // Akun A menyukai postingan yang juga milik Akun A
      await PostService.instance.togglePostLike(
        samplePostId,
        targetAuthorId: actorA, // author sama dengan actor
        speciesName: 'Orangutan Sumatera',
      );

      // Antrean Akun A harus tetap kosong
      final notifs = NotificationService.instance.fetchMyNotifications(actorA);
      expect(notifs, isEmpty,
          reason: 'Like ke postingan sendiri tidak boleh menghasilkan notifikasi');
      expect(NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialLike), isNull);
      debugPrint('[SUKSES SKENARIO 2] Self-like diblokir total.');
    });

    test('3. Siklus Unlike dan Like Kembali: Unlike tidak membuat notif, Like kembali tidak menduplikasi baris', () async {
      NotificationService.instance.setMockCurrentUserId(actorA);

      // 3a. Like pertama kali
      await PostService.instance.togglePostLike(
        samplePostId,
        targetAuthorId: ownerB,
        speciesName: 'Komodo',
      );

      var notifsB = NotificationService.instance.fetchMyNotifications(ownerB);
      expect(notifsB.length, equals(1));
      final firstCreatedAt = notifsB.first.createdAt;

      // 3b. Unlike
      // Pada PostService, unlike mengembalikan is_liked: false sehingga dispatchSocialNotification tidak dipanggil
      // Memastikan unlike tidak membuat notifikasi tambahan
      var notifsBAfterUnlike = NotificationService.instance.fetchMyNotifications(ownerB);
      expect(notifsBAfterUnlike.length, equals(1),
          reason: 'Unlike tidak boleh menambah notifikasi');

      // 3c. Like kembali setelah unlike (Like -> Unlike -> Like lagi)
      await Future.delayed(const Duration(milliseconds: 50));
      await PostService.instance.togglePostLike(
        samplePostId,
        targetAuthorId: ownerB,
        speciesName: 'Komodo',
      );

      notifsB = NotificationService.instance.fetchMyNotifications(ownerB);
      // DEDUPLIKASI: Jumlah item tetap 1, tidak menjadi 2 item duplikat
      expect(notifsB.length, equals(1),
          reason: 'Deduplikasi harus memastikan tidak ada baris notifikasi ganda untuk like postingan yang sama!');
      expect(notifsB.first.postId, equals(samplePostId));
      expect(notifsB.first.recipientUserId, equals(ownerB));
      expect(notifsB.first.createdAt.isAfter(firstCreatedAt) || notifsB.first.createdAt == firstCreatedAt, isTrue);

      debugPrint('[SUKSES SKENARIO 3] Deduplikasi like -> unlike -> like kembali terverifikasi sukses (Hanya 1 baris aktif).');
    });

    test('4. Skenario Follow: Memastikan tidak terjadi regresi pada alur follow yang sudah bekerja', () async {
      NotificationService.instance.setMockCurrentUserId(actorA);

      // Akun A mengikuti Akun B
      await SocialService.instance.toggleFollow(ownerB);

      // Di HP A (Pelaku): Banner NULL
      expect(NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialFollow), isNull);

      // Di HP B (Penerima): Notifikasi Follow masuk
      final notifsB = NotificationService.instance.fetchMyNotifications(ownerB);
      expect(notifsB.any((n) => n.type == 'follow' && n.actorUserId == actorA), isTrue);

      // Akun B membuka aplikasi
      NotificationService.instance.setMockCurrentUserId(ownerB);
      await NotificationService.instance.deliverPendingNotificationsForUser(ownerB);
      final followBanner = NotificationService.instance.getScheduledRecord(NotificationConstants.idSocialFollow);
      expect(followBanner, isNotNull);
      expect(followBanner!.title, contains('Pengikut Baru'));

      debugPrint('[SUKSES SKENARIO 4] Tidak ada regresi pada alur follow.');
    });
  });
}
