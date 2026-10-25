import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/utils/media_resolver.dart';
import 'package:faunova/features/feed/models/post_model.dart';
import 'package:faunova/features/feed/presentation/widgets/post_card.dart';

void main() {
  group('MASALAH A VERIFIKASI: Foto Berubah Antar Akun Teratasi', () {
    test('1. Verifikasi: Path lokal milik akun lain diselesaikan ke string kosong, TANPA fallback foto stok Unsplash', () {
      const uploaderLocalPath = '/data/user/0/com.example.faunova/cache/CAP8715336324506540322.jpg';
      const speciesName = 'Pangolin';
      const category = 'Manis javanica';

      // Pastikan file memang tidak ada di perangkat penerima (akun lain)
      expect(File(uploaderLocalPath).existsSync(), isFalse);

      final resolvedUrl = MediaResolver.resolvePhotoUrl(
        uploaderLocalPath,
        speciesName: speciesName,
        category: category,
      );

      // Verifikasi: Harus string kosong, TIDAK BOLEH memunculkan URL Unsplash hewan lain
      expect(resolvedUrl, isEmpty);
      expect(resolvedUrl.contains('unsplash.com'), isFalse);
      debugPrint('VERIFIKASI SUKSES: Akun lain menerima string kosong (bukan foto stok): "$resolvedUrl"');
    });

    test('2. Verifikasi: Path Supabase Storage tetap diselesaikan secara benar ke public storage URL', () {
      const storagePath = 'captures/3c0ef0d9-d475-4ddf-b031-dafa5508c5e6/scan_001.jpg';
      final resolvedStorage = MediaResolver.resolvePhotoUrl(storagePath);

      expect(resolvedStorage.startsWith('https://'), isTrue);
      expect(resolvedStorage.contains('/storage/v1/object/public/captures/'), isTrue);
      debugPrint('VERIFIKASI SUKSES: Path Supabase Storage diselesaikan ke: $resolvedStorage');
    });

    testWidgets('3. Verifikasi: PostCard menampilkan placeholder jujur (Icons.pets_rounded) saat foto lokal tidak ada', (WidgetTester tester) async {
      final postFromOtherAccount = PostModel(
        id: 'post-test-1',
        captureId: 'cap-test-1',
        caption: 'Observasi satwa Pangolin di habitat aslinya.',
        speciesName: 'Pangolin',
        category: 'Manis javanica',
        photoUrl: '/data/user/0/com.example.faunova/cache/CAP8715336324506540322.jpg',
        locationVisibility: 'coarse',
        blockSeq: 1,
        blockHash: 'hash-test',
        photoSha256: 'sha-test',
        authorId: 'user-uploader',
        authorName: 'Aniat',
        authorUsername: 'wowoktt',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCard(post: postFromOtherAccount),
          ),
        ),
      );
      await tester.pump();

      // Harus menampilkan placeholder jujur (ikon satwa netral Icons.pets_rounded)
      expect(find.byIcon(Icons.pets_rounded), findsOneWidget);
      // Tidak merender NetworkImage/Unsplash satwa lain
      expect(find.byType(Image), findsNothing);
      debugPrint('VERIFIKASI WIDGET SUKSES: PostCard akun lain menampilkan placeholder jujur tanpa gambar palsu!');
    });
  });
}
