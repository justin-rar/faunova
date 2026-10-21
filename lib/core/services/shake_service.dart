// ==============================================================================
// FAUNOVA SERVICE: ShakeService
// Pengelolaan Kuis Goyang HP (Accelerometer) & Kuota Server 3x/hari
// Sesuai Plan 5.8 (190-196, 440) & AGENTS.md (Sesi S15)
// ==============================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../features/game/models/shake_quiz_model.dart';
import 'timezone_service.dart';

class ShakeService {
  static final ShakeService instance = ShakeService._internal();
  ShakeService._internal();

  SupabaseClient? _client;
  final Uuid _uuid = const Uuid();

  @visibleForTesting
  void setMockClient(SupabaseClient client) {
    _client = client;
  }

  SupabaseClient? get _supabase {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // State demo / luring
  int _demoUsedQuota = 0;
  String? _demoQuotaDate;
  final Map<String, Map<String, dynamic>> _demoClaims = {};

  @visibleForTesting
  void resetDemoQuota({int used = 0, String? date}) {
    _demoUsedQuota = used;
    _demoQuotaDate = date;
    _demoClaims.clear();
  }

  // ============================================================================
  // KUOTA & KLAIM SHAKE QUIZ (Plan 192, 194)
  // ============================================================================

  /// Memeriksa sisa kuota goyang HP harian (3x per hari WIB)
  Future<ShakeQuotaModel> getShakeQuota() async {
    final client = _supabase;
    final currentWibDate = TimeZoneService.getCurrentDateWibString();

    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client.rpc('get_shake_quota');
        if (res is Map<String, dynamic>) {
          return ShakeQuotaModel.fromJson(res);
        }
      } catch (e) {
        debugPrint('ShakeService getShakeQuota error: $e. Fallback ke lokal.');
      }
    }

    // Fallback mode luring / demo
    if (_demoQuotaDate != currentWibDate) {
      _demoUsedQuota = 0;
      _demoQuotaDate = currentWibDate;
    }

    return ShakeQuotaModel(
      usedQuota: _demoUsedQuota,
      maxQuota: 3,
      remainingQuota: math.max(0, 3 - _demoUsedQuota),
      dateWib: currentWibDate,
    );
  }

  /// Mengklaim 1 soal kejutan kuis goyang HP
  /// Aturan Keras 5: Kunci jawaban TIDAK BOLEH dikirim saat klaim!
  Future<ShakeQuizClaimModel> claimShakeQuiz({String? customIdempotencyKey}) async {
    final client = _supabase;
    final idempotencyKey = customIdempotencyKey ?? _uuid.v4();
    final currentWibDate = TimeZoneService.getCurrentDateWibString();

    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client.rpc('claim_shake_quiz', params: {
          'p_idempotency_key': idempotencyKey,
        });
        if (res is Map<String, dynamic>) {
          return ShakeQuizClaimModel.fromJson(res);
        }
      } catch (e) {
        debugPrint('ShakeService claimShakeQuiz Supabase error: $e.');
        throw Exception(e.toString());
      }
    }

    // Fallback demo / luring
    if (_demoQuotaDate != currentWibDate) {
      _demoUsedQuota = 0;
      _demoQuotaDate = currentWibDate;
    }

    if (_demoClaims.containsKey(idempotencyKey)) {
      final existing = _demoClaims[idempotencyKey]!;
      return ShakeQuizClaimModel(
        claimId: existing['claim_id'] as String,
        questionId: existing['question_id'] as String,
        category: existing['category'] as String,
        questionText: existing['question'] as String,
        options: List<String>.from(existing['options'] as List),
        remainingQuota: math.max(0, 3 - _demoUsedQuota),
        alreadyAnswered: existing['already_answered'] as bool? ?? false,
        message: 'Kuis goyang HP berhasil dipulihkan.',
      );
    }

    if (_demoUsedQuota >= 3) {
      return const ShakeQuizClaimModel(
        claimId: '',
        questionId: '',
        category: '',
        questionText: '',
        options: [],
        remainingQuota: 0,
        alreadyAnswered: false,
        quotaExceeded: true,
        message: 'Kuota goyang HP harian kamu sudah habis (3/3). Kuota diperbarui kembali besok pukul 00:00 WIB.',
      );
    }

    final claimId = _uuid.v4();
    final question = _getRandomDemoQuestion();
    _demoUsedQuota++;

    _demoClaims[idempotencyKey] = {
      'claim_id': claimId,
      'question_id': question['id'],
      'category': question['category'],
      'question': question['question'],
      'options': question['options'],
      'correct_option': question['correct_option'],
      'explanation': question['explanation'],
      'already_answered': false,
    };

    return ShakeQuizClaimModel(
      claimId: claimId,
      questionId: question['id'] as String,
      category: question['category'] as String,
      questionText: question['question'] as String,
      options: List<String>.from(question['options'] as List),
      remainingQuota: math.max(0, 3 - _demoUsedQuota),
      alreadyAnswered: false,
      quotaExceeded: false,
      message: 'Soal kejutan berhasil ditemukan dari goyangan HP!',
    );
  }

  /// Menjawab soal kuis goyang HP
  Future<ShakeQuizResultModel> answerShakeQuiz({
    required String claimId,
    required int selectedOption,
  }) async {
    final client = _supabase;

    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client.rpc('answer_shake_quiz', params: {
          'p_claim_id': claimId,
          'p_selected_option': selectedOption,
        });
        if (res is Map<String, dynamic>) {
          return ShakeQuizResultModel.fromJson(res);
        }
      } catch (e) {
        debugPrint('ShakeService answerShakeQuiz Supabase error: $e.');
        throw Exception(e.toString());
      }
    }

    // Fallback mode luring / demo
    Map<String, dynamic>? targetClaim;
    for (final claim in _demoClaims.values) {
      if (claim['claim_id'] == claimId) {
        targetClaim = claim;
        break;
      }
    }

    if (targetClaim == null) {
      throw Exception('Klaim kuis goyang HP tidak ditemukan.');
    }

    if (targetClaim['already_answered'] == true) {
      throw Exception('Kuis goyang HP ini sudah pernah dijawab.');
    }

    final correctOption = targetClaim['correct_option'] as int;
    final isCorrect = (selectedOption == correctOption);
    targetClaim['already_answered'] = true;

    return ShakeQuizResultModel(
      claimId: claimId,
      questionId: targetClaim['question_id'] as String,
      selectedOption: selectedOption,
      isCorrect: isCorrect,
      correctOption: correctOption,
      explanation: targetClaim['explanation'] as String? ?? '',
      message: isCorrect
          ? 'Hebat! Jawabanmu benar. Progres lencana Si Goyang bertambah.'
          : 'Jawabanmu kurang tepat. Pelajari pembahasannya!',
    );
  }

  // ============================================================================
  // DETEKSI GOYANG HP (ACCELEROMETER SENSORS_PLUS) (Plan 191)
  // ============================================================================

  /// Memulai listener akselerometer dengan ambang batas (threshold), haptic, dan debounce
  StreamSubscription<AccelerometerEvent>? listenToShakeEvents({
    required VoidCallback onShakeDetected,
    double threshold = 22.0, // m/s^2 (Guncangan fisik nyata)
    Duration debounceDuration = const Duration(seconds: 3),
  }) {
    DateTime? lastShakeTime;

    try {
      return accelerometerEventStream().listen((event) {
        final double magnitude = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );

        if (magnitude >= threshold) {
          final now = DateTime.now();
          if (lastShakeTime == null || now.difference(lastShakeTime!) > debounceDuration) {
            lastShakeTime = now;
            // Haptic feedback saat goyangan valid terdeteksi (Plan 191)
            HapticFeedback.mediumImpact();
            onShakeDetected();
          }
        }
      });
    } catch (e) {
      debugPrint('ShakeService listenToShakeEvents error: $e');
      return null;
    }
  }

  Map<String, dynamic> _getRandomDemoQuestion() {
    const list = [
      {
        'id': 'sq-001',
        'category': 'Reptilia',
        'question': 'Berapa rata-rata panjang Komodo (Varanus komodoensis) jantan dewasa di habitat aslinya?',
        'options': ['1,5 - 2 meter', '2,5 - 3 meter', '3,5 - 4 meter', '4,5 - 5 meter'],
        'correct_option': 1,
        'explanation': 'Komodo jantan dewasa umumnya berukuran antara 2,5 hingga 3 meter dengan berat rata-rata 70-90 kg.',
      },
      {
        'id': 'sq-002',
        'category': 'Aves',
        'question': 'Spesies Cenderawasih yang menjadi maskot resmi PON XX Papua adalah...',
        'options': ['Cenderawasih Kuning Kecil', 'Cenderawasih Merah', 'Cenderawasih Biru', 'Cenderawasih Mati-Kawat'],
        'correct_option': 0,
        'explanation': 'Cenderawasih Kuning Kecil (Paradisaea minor) merupakan salah satu fauna identitas paling tersohor di Pulau Papua.',
      },
      {
        'id': 'sq-003',
        'category': 'Mamalia',
        'question': 'Habitat utama Rusa Bawean (Axis kuhlii) yang merupakan spesies terancam punah berada di...',
        'options': ['Pulau Bawean, Jawa Timur', 'Taman Nasional Baluran', 'Kepulauan Karimunjawa', 'Pulau Menjangan, Bali'],
        'correct_option': 0,
        'explanation': 'Rusa Bawean hidup secara endemik terbatas di kawasan perbukitan Pulau Bawean, Laut Jawa.',
      },
    ];

    final randomIndex = math.Random().nextInt(list.length);
    return list[randomIndex];
  }
}
