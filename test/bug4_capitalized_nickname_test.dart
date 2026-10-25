import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/features/profile/models/public_profile_model.dart';

void main() {
  group('BUG 4: Preservasi Huruf Kapital Nickname / Display Name', () {
    test('PublicProfileModel menjaga huruf kapital pada displayName dan username tetap lowercase', () {
      final json = {
        'id': 'test-uuid-444',
        'username': 'wowoktt', // Username selalu lowercase sesuai aturan keras
        'display_name': 'WowokTT', // Nickname mempertahankan huruf kapital
        'bio': 'Pengamat satwa nokturnal',
      };

      final profile = PublicProfileModel.fromJson(json);

      expect(profile.username, equals('wowoktt'), reason: 'Username wajib huruf kecil');
      expect(profile.displayName, equals('WowokTT'), reason: 'Display name/nickname wajib menjaga huruf kapital');
    });

    test('PublicProfileModel fallback cerdas jika display_name kosong mengambil full_name atau username', () {
      final json = {
        'id': 'test-uuid-555',
        'username': 'badak_jawa',
        'display_name': '',
        'full_name': 'Badak Jawa Hebat',
      };

      final profile = PublicProfileModel.fromJson(json);

      expect(profile.displayName, equals('Badak Jawa Hebat'), reason: 'Fallback ke full_name menjaga huruf kapital');
      expect(profile.username, equals('badak_jawa'), reason: 'Username tetap huruf kecil');
    });
  });
}
