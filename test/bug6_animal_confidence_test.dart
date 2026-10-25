import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/features/camera/models/scan_result_model.dart';

void main() {
  group('BUG 6: Evaluasi Ambang Confidence Identifikasi Satwa', () {
    test('ScanResultModel memproses confidence score secara dinamis dari respon AI', () {
      final jsonHighConfidence = {
        'scanId': 'scan-111',
        'isAnimal': true,
        'result': {
          'isAnimal': true,
          'name': 'Kupu-kupu Raja',
          'categoryOrSpecies': 'Danaus plexippus',
          'description': 'Kupu-kupu dengan corak oranye dan hitam yang khas.',
          'additionalFact': 'Mampu bermigrasi ribuan kilometer.',
          'confidence': 0.96,
        },
      };

      final resultHigh = ScanResultModel.fromJson(jsonHighConfidence);
      expect(resultHigh.confidence, equals(0.96));
      expect(resultHigh.confidencePercentText, equals('96%'));
      expect(resultHigh.confidenceLabel, equals('Sangat yakin'));

      final jsonMediumConfidence = {
        'scanId': 'scan-222',
        'isAnimal': true,
        'result': {
          'isAnimal': true,
          'name': 'Kucing Kampung',
          'categoryOrSpecies': 'Felis catus',
          'confidence': 0.72,
        },
      };

      final resultMedium = ScanResultModel.fromJson(jsonMediumConfidence);
      expect(resultMedium.confidence, equals(0.72));
      expect(resultMedium.confidencePercentText, equals('72%'));
      expect(resultMedium.confidenceLabel, equals('Cukup yakin'));
    });

    test('Ambang batas rendah (confidence < 0.40) menolak identifikasi spekulatif/ambigu', () {
      final jsonLowConfidence = {
        'scanId': 'scan-333',
        'isAnimal': false,
        'status': 'rejected_not_animal',
        'result': {
          'isAnimal': false,
          'confidence': 0.25,
          'additionalFact': 'Objek terlalu buram atau gelap untuk diidentifikasi secara akurat.',
        },
      };

      final resultLow = ScanResultModel.fromJson(jsonLowConfidence);
      expect(resultLow.isAnimal, isFalse);
      expect(resultLow.confidence, equals(0.25));
      expect(resultLow.additionalFact, contains('buram atau gelap'));
    });
  });
}
