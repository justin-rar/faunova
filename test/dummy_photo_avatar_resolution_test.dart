import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/features/feed/models/post_model.dart';
import 'package:faunova/features/profile/models/public_profile_model.dart';

void main() {
  group('Dummy Data & Photo Resolution Tests (Plan 5.7, 5.9, 18)', () {
    test('PostModel.fromJson fixes mismatched animal photos from legacy seed data', () {
      // 1. Komodo dengan foto macan tutul
      final komodoJson = {
        'post_id': '11111111-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'species_name': 'Komodo',
        'photo_object_path': 'https://images.unsplash.com/photo-1544979590-37e9b47eb705?w=900&auto=format&fit=crop&q=80',
        'author_username': 'wayan_bali',
        'author_name': 'Dr. Wayan Suastika, M.Si',
      };
      final komodoPost = PostModel.fromJson(komodoJson);
      expect(komodoPost.photoUrl, contains('photo-1562578057')); // Foto komodo dragon asli
      expect(komodoPost.authorAvatar, isNotNull);
      expect(komodoPost.authorAvatar, contains('photo-1544168190')); // Avatar dokter realistis

      // 2. Orangutan Kalimantan dengan foto burung
      final orangutanJson = {
        'post_id': '44444444-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'species_name': 'Orangutan Kalimantan',
        'photo_object_path': 'https://images.unsplash.com/photo-1535083783855-76ae62b2914e?w=900&auto=format&fit=crop&q=80',
        'author_username': 'borneo_wildlife',
      };
      final orangutanPost = PostModel.fromJson(orangutanJson);
      expect(orangutanPost.photoUrl, contains('photo-1552656504')); // Foto orangutan asli
      expect(orangutanPost.authorAvatar, contains('photo-1522075469')); // Avatar konservasionis

      // 3. Jalak Bali dengan foto burung nuri hijau
      final jalakJson = {
        'post_id': '22222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'species_name': 'Jalak Bali',
        'photo_object_path': 'https://images.unsplash.com/photo-1552728089-57bdde30beb3?w=900&auto=format&fit=crop&q=80',
        'author_username': 'budi_satria',
      };
      final jalakPost = PostModel.fromJson(jalakJson);
      expect(jalakPost.photoUrl, contains('photo-1521566652')); // Foto jalak bali putih asli
      expect(jalakPost.authorAvatar, contains('photo-1507003211'));

      // 4. Cenderawasih dengan foto macaw
      final cenderawasihJson = {
        'post_id': '55555555-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'species_name': 'Cenderawasih Kuning Kecil',
        'photo_object_path': 'https://images.unsplash.com/photo-1452570053594-1b985d6ea890?w=900&auto=format&fit=crop&q=80',
        'author_username': 'dewi_papua',
      };
      final cenderawasihPost = PostModel.fromJson(cenderawasihJson);
      expect(cenderawasihPost.photoUrl, contains('photo-1618098750')); // Burung kuning eksotis
      expect(cenderawasihPost.authorAvatar, contains('photo-1534751516'));

      // 5. Penyu Hijau dengan foto penyelam manusia
      final penyuJson = {
        'post_id': '66666666-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'species_name': 'Penyu Hijau',
        'photo_object_path': 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=900&auto=format&fit=crop&q=80',
        'author_username': 'faiz_ocean',
      };
      final penyuPost = PostModel.fromJson(penyuJson);
      expect(penyuPost.photoUrl, contains('photo-1437622368')); // Penyu berenang di laut lepas
      expect(penyuPost.authorAvatar, contains('photo-1500648767'));
    });

    test('PublicProfileModel.fromJson resolves realistic avatars for dummy accounts when avatar_path is null in Supabase', () {
      final profiles = [
        {'id': 'aa111111-1111-1111-1111-111111111111', 'username': 'wayan_bali', 'display_name': 'Dr. Wayan Suastika, M.Si', 'avatar_path': null},
        {'id': 'bb222222-2222-2222-2222-222222222222', 'username': 'siti_sumatera', 'display_name': 'Siti Sarah, S.Hut', 'avatar_path': null},
        {'id': 'cc333333-3333-3333-3333-333333333333', 'username': 'budi_satria', 'display_name': 'Budi Satria Wibowo', 'avatar_path': null},
        {'id': 'dd444444-4444-4444-4444-444444444444', 'username': 'borneo_wildlife', 'display_name': 'Dedi Pratama', 'avatar_path': null},
        {'id': 'ee555555-5555-5555-5555-555555555555', 'username': 'dewi_papua', 'display_name': 'Dewi Lestari', 'avatar_path': null},
        {'id': 'ff666666-6666-6666-6666-666666666666', 'username': 'faiz_ocean', 'display_name': 'Faiz Alamsyah', 'avatar_path': null},
      ];

      for (final pJson in profiles) {
        final profile = PublicProfileModel.fromJson(pJson);
        expect(profile.avatarPath, isNotNull, reason: 'Avatar should not be null for ${profile.username}');
        expect(profile.avatarPath!.startsWith('https://images.unsplash.com/'), isTrue);
      }
    });

    test('Custom user with real avatar retains their own avatar', () {
      final customJson = {
        'id': '99999999-9999-9999-9999-999999999999',
        'username': 'gustinmr7',
        'display_name': 'Gustin MR',
        'avatar_path': 'https://custom.storage/my_avatar.png',
      };
      final profile = PublicProfileModel.fromJson(customJson);
      expect(profile.avatarPath, equals('https://custom.storage/my_avatar.png'));
    });
  });
}
