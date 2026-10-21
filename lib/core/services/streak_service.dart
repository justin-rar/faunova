// ==============================================================================
// FAUNOVA SERVICE: StreakService
// Pengelolaan Check-in Streak Harian & Tantangan Hari Ini
// Sesuai Plan 5.8 (168-170, 197-200), AGENTS.md (Aturan Keras 2 & 5)
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/game/models/daily_challenge_model.dart';
import '../../features/game/models/streak_status_model.dart';
import 'encrypted_storage_service.dart';
import 'notification_service.dart';
import 'timezone_service.dart';

class StreakService {
  static final StreakService instance = StreakService._internal();
  StreakService._internal();

  SupabaseClient? _client;

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

  // State in-memory untuk mode demo / luring
  int _demoStreakCount = 5;
  String? _demoLastClaimDate;
  final Map<String, Map<String, dynamic>> _demoDailyChallengeLogs = {};

  @visibleForTesting
  void resetDemoState({int streak = 5, String? lastClaimDate}) {
    _demoStreakCount = streak;
    _demoLastClaimDate = lastClaimDate;
    _demoDailyChallengeLogs.clear();
  }

  // ============================================================================
  // STREAK OBSERVASI HARIAN (Plan 168-170)
  // ============================================================================

  /// Mengambil status streak terkini dari server (atau cache luring)
  Future<StreakStatusModel> getStreakStatus() async {
    final client = _supabase;
    final currentWibDate = TimeZoneService.getCurrentDateWibString();

    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client.rpc('get_streak_status');
        if (res is Map<String, dynamic>) {
          final status = StreakStatusModel.fromJson(res);
          // Simpan cache ke Hive terenkripsi
          await EncryptedStorageService.instance.saveSetting('cached_streak_count', status.streakCount);
          await EncryptedStorageService.instance.saveSetting('cached_last_streak_claim', status.lastClaimDate);
          return status;
        }
      } catch (e) {
        debugPrint('StreakService getStreakStatus Supabase error: $e. Menggunakan fallback lokal.');
      }
    }

    // Fallback mode luring / demo
    final cachedStreak = EncryptedStorageService.instance.getSetting('cached_streak_count', defaultValue: _demoStreakCount) as int;
    final cachedDate = EncryptedStorageService.instance.getSetting('cached_last_streak_claim', defaultValue: _demoLastClaimDate) as String?;

    final isClaimedToday = (cachedDate != null && cachedDate == currentWibDate);

    return StreakStatusModel(
      streakCount: cachedStreak,
      lastClaimDate: cachedDate,
      isClaimedToday: isClaimedToday,
      wibToday: currentWibDate,
      message: isClaimedToday ? 'Streak sudah diklaim hari ini.' : 'Belum check-in hari ini.',
    );
  }

  /// Melakukan klaim streak harian (Aturan Keras 2: dihitung di server)
  Future<StreakStatusModel> claimDailyStreak() async {
    final client = _supabase;
    final currentWibDate = TimeZoneService.getCurrentDateWibString();

    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client.rpc('claim_daily_streak');
        if (res is Map<String, dynamic>) {
          final status = StreakStatusModel.fromJson(res);
          await EncryptedStorageService.instance.saveSetting('cached_streak_count', status.streakCount);
          await EncryptedStorageService.instance.saveSetting('cached_last_streak_claim', status.lastClaimDate);
          await NotificationService.instance.cancelStreakReminderToday();
          return status;
        }
      } catch (e) {
        debugPrint('StreakService claimDailyStreak Supabase error: $e. Menggunakan fallback lokal.');
      }
    }

    // Simulasi luring deterministik
    if (_demoLastClaimDate == currentWibDate) {
      return StreakStatusModel(
        streakCount: _demoStreakCount,
        lastClaimDate: _demoLastClaimDate,
        isClaimedToday: true,
        wibToday: currentWibDate,
        isNewClaim: false,
        message: 'Kamu sudah melakukan check-in streak hari ini. Kembali lagi besok!',
      );
    }

    // Evaluasi kelanjutan streak
    // Hitung selisih hari jika ada tanggal sebelumnya
    int newStreak = 1;
    if (_demoLastClaimDate != null) {
      try {
        final lastDate = DateTime.parse(_demoLastClaimDate!);
        final todayDate = DateTime.parse(currentWibDate);
        final diffDays = todayDate.difference(lastDate).inDays;
        if (diffDays == 1) {
          newStreak = _demoStreakCount + 1;
        } else {
          newStreak = 1; // Terlewat > 1 hari -> reset ke 1
        }
      } catch (_) {
        newStreak = 1;
      }
    } else {
      newStreak = _demoStreakCount + 1;
    }

    _demoStreakCount = newStreak;
    _demoLastClaimDate = currentWibDate;

    await EncryptedStorageService.instance.saveSetting('cached_streak_count', newStreak);
    await EncryptedStorageService.instance.saveSetting('cached_last_streak_claim', currentWibDate);
    await NotificationService.instance.cancelStreakReminderToday();

    return StreakStatusModel(
      streakCount: newStreak,
      lastClaimDate: currentWibDate,
      isClaimedToday: true,
      wibToday: currentWibDate,
      isNewClaim: true,
      message: 'Check-in berhasil! Streak observasi kamu kini $newStreak hari berturut-turut.',
    );
  }

  // ============================================================================
  // TANTANGAN HARI INI (Plan 197-200, Hard Rule 5)
  // ============================================================================

  /// Mengambil soal Tantangan Hari Ini
  /// Aturan Keras 5: Kunci jawaban TIDAK BOLEH dikirim jika belum dijawab!
  Future<DailyChallengeModel> getDailyChallenge() async {
    final client = _supabase;
    final currentWibDate = TimeZoneService.getCurrentDateWibString();

    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client.rpc('get_daily_challenge');
        if (res is Map<String, dynamic>) {
          return DailyChallengeModel.fromJson(res);
        }
      } catch (e) {
        debugPrint('StreakService getDailyChallenge Supabase error: $e. Menggunakan fallback lokal.');
      }
    }

    // Fallback mode luring / demo
    final seed = _getDemoChallengeQuestion(currentWibDate);
    final log = _demoDailyChallengeLogs[currentWibDate];

    if (log != null) {
      return DailyChallengeModel(
        challengeDate: currentWibDate,
        questionId: seed['id'] as String,
        category: seed['category'] as String,
        questionText: seed['question'] as String,
        options: List<String>.from(seed['options'] as List),
        alreadyAnswered: true,
        selectedOption: log['selected_option'] as int?,
        isCorrect: log['is_correct'] as bool?,
        correctOption: seed['correct_option'] as int?,
        explanation: seed['explanation'] as String?,
        pointsEarned: (log['is_correct'] == true) ? 50 : 0,
        message: 'Tantangan hari ini sudah dijawab.',
      );
    }

    // BELUM DIJAWAB: Kunci jawaban sengaja dihilangkan (Aturan Keras 5)
    return DailyChallengeModel(
      challengeDate: currentWibDate,
      questionId: seed['id'] as String,
      category: seed['category'] as String,
      questionText: seed['question'] as String,
      options: List<String>.from(seed['options'] as List),
      alreadyAnswered: false,
      selectedOption: null,
      isCorrect: null,
      correctOption: null, // RAHASIA
      explanation: null,   // RAHASIA
      pointsEarned: 0,
      message: 'Tantangan harian siap dijawab.',
    );
  }

  /// Menjawab Tantangan Hari Ini (Aturan Keras 2: diverifikasi server)
  Future<DailyChallengeModel> answerDailyChallenge(int selectedOption) async {
    final client = _supabase;
    final currentWibDate = TimeZoneService.getCurrentDateWibString();

    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client.rpc('answer_daily_challenge', params: {
          'p_selected_option': selectedOption,
        });
        if (res is Map<String, dynamic>) {
          await NotificationService.instance.cancelChallengeReminderToday();
          return DailyChallengeModel.fromJson(res);
        }
      } catch (e) {
        debugPrint('StreakService answerDailyChallenge Supabase error: $e.');
        throw Exception(e.toString());
      }
    }

    // Fallback mode luring / demo
    if (_demoDailyChallengeLogs.containsKey(currentWibDate)) {
      throw Exception('Tantangan hari ini sudah dijawab. Tantangan berikutnya tersedia pukul 00:00 WIB.');
    }

    final seed = _getDemoChallengeQuestion(currentWibDate);
    final correctOpt = seed['correct_option'] as int;
    final isCorrect = (selectedOption == correctOpt);

    _demoDailyChallengeLogs[currentWibDate] = {
      'selected_option': selectedOption,
      'is_correct': isCorrect,
      'answered_at': DateTime.now().toIso8601String(),
    };

    await NotificationService.instance.cancelChallengeReminderToday();

    return DailyChallengeModel(
      challengeDate: currentWibDate,
      questionId: seed['id'] as String,
      category: seed['category'] as String,
      questionText: seed['question'] as String,
      options: List<String>.from(seed['options'] as List),
      alreadyAnswered: true,
      selectedOption: selectedOption,
      isCorrect: isCorrect,
      correctOption: correctOpt,
      explanation: seed['explanation'] as String?,
      pointsEarned: isCorrect ? 50 : 0,
      message: isCorrect
          ? 'Luar biasa! Jawabanmu benar (+50 Poin).'
          : 'Jawabanmu kurang tepat. Pelajari pembahasannya untuk menambah wawasan!',
    );
  }

  Map<String, dynamic> _getDemoChallengeQuestion(String dateWib) {
    const questions = [
      {
        'id': 'd1111111-1111-1111-1111-111111111111',
        'category': 'Mamalia',
        'question': 'Berapa jumlah kantung tenggorokan pada Bekantan (Nasalis larvatus) jantan dewasa yang digunakan untuk memperkeras suara panggilannya?',
        'options': ['1 kantung resonansi besar', '2 kantung simetris', '3 rongga udara', 'Tidak memiliki kantung'],
        'correct_option': 0,
        'explanation': 'Bekantan jantan memiliki satu kantung suara (laryngeal sac) besar yang menggembung di bawah leher untuk memperkeras vokalisasi panggilan teritorial.',
      },
      {
        'id': 'd2222222-2222-2222-2222-222222222222',
        'category': 'Aves',
        'question': 'Burung Maleo (Macrocephalon maleo) meletakkan telurnya untuk ditetaskan menggunakan...',
        'options': ['Mengerami di pohon', 'Panas bumi atau pasir pantai vulkanik', 'Gua kapur lembap', 'Sarang lumpur di rawa'],
        'correct_option': 1,
        'explanation': 'Maleo tidak mengerami telurnya, melainkan menguburnya di tanah berpasir vulkanik atau area geotermal Sulawesi yang hangat.',
      },
      {
        'id': 'd3333333-3333-3333-3333-333333333333',
        'category': 'Reptilia',
        'question': 'Organ Jacobson pada Komodo (Varanus komodoensis) terletak di bagian tubuh mana?',
        'options': ['Langit-langit rongga mulut', 'Ujung moncong hidung', 'Di balik lipatan leher', 'Sisi samping kepala'],
        'correct_option': 0,
        'explanation': 'Organ Jacobson (vomeronasal) terletak di langit-langit mulut Komodo dan menerima partikel aroma yang dibawa oleh lidah bercabangnya.',
      },
    ];

    final index = (dateWib.hashCode.abs()) % questions.length;
    return questions[index];
  }
}
