// ==============================================================================
// FAUNOVA TEST: Social Notification & Realtime Center Test
// Menguji Pusat Notifikasi Sosial In-App, Realtime Listener, & Pemisahan Aktor/Penerima
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/services/notification_service.dart';
import 'package:faunova/core/services/post_service.dart';
import 'package:faunova/core/services/social_service.dart';
import 'package:faunova/features/feed/presentation/widgets/social_notification_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    NotificationService.instance.clearNotificationQueues();
  });

  tearDown(() {
    NotificationService.instance.clearNotificationQueues();
    NotificationService.instance.setMockCurrentUserId(null);
  });

  group('Pusat Notifikasi Sosial & Model Serialisasi', () {
    test('SocialNotificationItem serialisasi dan deserialisasi lengkap', () {
      final now = DateTime.now();
      final item = SocialNotificationItem(
        id: 'notif-123',
        recipientUserId: 'user-budi',
        actorUserId: 'user-wayan',
        actorName: 'Dr. Wayan Suastika',
        actorUsername: 'wayan_bali',
        actorAvatar: 'avatar/wayan.jpg',
        type: 'follow',
        postId: 'post-999',
        speciesName: 'Komodo',
        title: 'Pengikut Baru! 👥',
        body: 'Dr. Wayan Suastika mulai mengikuti linimasa satwa Anda.',
        isRead: false,
        createdAt: now,
      );

      final json = item.toJson();
      expect(json['id'], equals('notif-123'));
      expect(json['recipient_user_id'], equals('user-budi'));
      expect(json['actor_user_id'], equals('user-wayan'));
      expect(json['actor_name'], equals('Dr. Wayan Suastika'));
      expect(json['actor_username'], equals('wayan_bali'));
      expect(json['actor_avatar'], equals('avatar/wayan.jpg'));
      expect(json['type'], equals('follow'));

      final parsed = SocialNotificationItem.fromJson(json);
      expect(parsed.id, equals('notif-123'));
      expect(parsed.recipientUserId, equals('user-budi'));
      expect(parsed.actorUserId, equals('user-wayan'));
      expect(parsed.actorName, equals('Dr. Wayan Suastika'));
      expect(parsed.actorUsername, equals('wayan_bali'));
      expect(parsed.actorAvatar, equals('avatar/wayan.jpg'));
      expect(parsed.isRead, isFalse);
    });

    test('NotificationService: unreadCountNotifier dan markAllAsRead bekerja idempoten', () async {
      const recipientId = 'user-budi';
      NotificationService.instance.setMockCurrentUserId(recipientId);

      // Simulasikan 2 notifikasi masuk ke user-budi
      await NotificationService.instance.dispatchSocialNotification(
        recipientUserId: recipientId,
        actorUserId: 'user-wayan',
        actorName: 'Dr. Wayan',
        type: 'follow',
      );

      await NotificationService.instance.dispatchSocialNotification(
        recipientUserId: recipientId,
        actorUserId: 'user-siti',
        actorName: 'Siti Rahmawati',
        type: 'like',
        speciesName: 'Jalak Bali',
      );

      final myNotifs = NotificationService.instance.fetchMyNotifications(recipientId);
      expect(myNotifs.length, equals(2));
      expect(myNotifs[0].isRead, isFalse);
      expect(myNotifs[1].isRead, isFalse);

      // Tandai semua dibaca
      await NotificationService.instance.markAllAsRead();
      expect(NotificationService.instance.unreadCountNotifier.value, equals(0));

      final updated = NotificationService.instance.fetchMyNotifications(recipientId);
      expect(updated.every((n) => n.isRead), isTrue);
    });

    test('Aturan Keras: Follow dan Like ke diri sendiri TIDAK membuat notifikasi', () async {
      const selfId = 'user-kolektor-saya';
      NotificationService.instance.setMockCurrentUserId(selfId);

      // Aksi ke diri sendiri
      await NotificationService.instance.dispatchSocialNotification(
        recipientUserId: selfId,
        actorUserId: selfId,
        actorName: 'Saya Sendiri',
        type: 'follow',
      );

      await NotificationService.instance.dispatchSocialNotification(
        recipientUserId: selfId,
        actorUserId: selfId,
        actorName: 'Saya Sendiri',
        type: 'like',
        speciesName: 'Komodo',
      );

      final notifs = NotificationService.instance.fetchMyNotifications(selfId);
      expect(notifs, isEmpty);
      expect(NotificationService.instance.unreadCountNotifier.value, equals(0));
    });
  });

  group('SocialNotificationSheet Widget Test', () {
    testWidgets('Menampilkan empty state saat tidak ada notifikasi', (tester) async {
      NotificationService.instance.setMockCurrentUserId('user-baru');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SocialNotificationSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pusat Notifikasi'), findsOneWidget);
      expect(find.text('Belum Ada Notifikasi'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('Menampilkan daftar notifikasi follow dan like dengan rapi', (tester) async {
      const myId = 'user-kolektor';
      NotificationService.instance.setMockCurrentUserId(myId);

      // Masukkan notifikasi dummy ke memori
      await NotificationService.instance.dispatchSocialNotification(
        recipientUserId: myId,
        actorUserId: 'user-wayan',
        actorName: 'Dr. Wayan',
        type: 'follow',
      );

      await NotificationService.instance.dispatchSocialNotification(
        recipientUserId: myId,
        actorUserId: 'user-siti',
        actorName: 'Siti Rahmawati',
        type: 'like',
        speciesName: 'Harimau Sumatera',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SocialNotificationSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pusat Notifikasi'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('Dr. Wayan')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('Siti Rahmawati')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.person_add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });
}
