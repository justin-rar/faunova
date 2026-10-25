// ==============================================================================
// FAUNOVA SERVICE: QuizService
// Layanan kuis biologi satwa liar, integrasi RPC server, dan kalkulasi skor
// Sesuai Plan 46, 180-186, 277 & AGENTS.md (Sesi S13)
// ==============================================================================

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'encrypted_storage_service.dart';
import '../../features/game/models/quiz_question_model.dart';
import '../../features/game/models/quiz_session_model.dart';
import '../../features/game/models/quiz_result_model.dart';

class QuizException implements Exception {
  final String message;
  final String code;

  const QuizException(this.message, {this.code = 'QUIZ_ERROR'});

  @override
  String toString() => message;
}

class QuizAnswerCheckResult {
  final bool isCorrect;
  final int correctOption;
  final String explanation;

  const QuizAnswerCheckResult({
    required this.isCorrect,
    required this.correctOption,
    required this.explanation,
  });
}

class QuizService {
  static final QuizService instance = QuizService._internal();
  QuizService._internal();

  SupabaseClient? _getSupabaseClient() {
    return AppConfig.supabaseClient;
  }

  /// Memulai sesi kuis baru via RPC server `start_quiz_session`
  /// Aturan Keras AGENTS.md: Kunci jawaban TIDAK PERNAH dikirim ke klien!
  Future<QuizSessionModel> startQuizSession() async {
    final client = _getSupabaseClient();
    final user = client?.auth.currentUser;

    if (AppConfig.isDemoMode || client == null || user == null) {
      return _startDemoQuizSession();
    }

    try {
      final response = await client.rpc('start_quiz_session');
      if (response == null) {
        throw const QuizException('Gagal memulai sesi kuis: respons server kosong.');
      }

      final Map<String, dynamic> data = response is Map
          ? Map<String, dynamic>.from(response)
          : Map<String, dynamic>.from((response as List).first as Map);

      return QuizSessionModel.fromJson(data);
    } catch (e) {
      debugPrint('QuizService startQuizSession server error: $e, beralih ke mode demo offline.');
      return _startDemoQuizSession();
    }
  }

  /// Menyelesaikan sesi kuis via RPC server `finish_quiz_session`
  /// Seluruh skor dihitung ulang secara deterministik oleh server database
  Future<QuizResultModel> finishQuizSession({
    required String sessionId,
    required List<QuizAnswerInput> answers,
  }) async {
    final client = _getSupabaseClient();
    final user = client?.auth.currentUser;

    if (AppConfig.isDemoMode || client == null || user == null || sessionId.startsWith('demo-session-')) {
      return _finishDemoQuizSession(sessionId, answers);
    }

    try {
      final answersJson = answers.map((a) => a.toJson()).toList();
      final response = await client.rpc(
        'finish_quiz_session',
        params: {
          'p_session_id': sessionId,
          'p_answers': answersJson,
        },
      );

      if (response == null) {
        throw const QuizException('Gagal menyelesaikan kuis: respons server kosong.');
      }

      final Map<String, dynamic> data = response is Map
          ? Map<String, dynamic>.from(response)
          : Map<String, dynamic>.from((response as List).first as Map);

      final result = QuizResultModel.fromJson(data);

      // Simpan skor tertinggi ke cache Hive terenkripsi (Plan 186)
      await EncryptedStorageService.instance.saveBestQuizScore(result.bestQuizScore);

      return result;
    } catch (e) {
      debugPrint('QuizService finishQuizSession error: $e, beralih ke evaluator demo offline.');
      return _finishDemoQuizSession(sessionId, answers);
    }
  }

  /// Memverifikasi satu jawaban kuis secara instan (gaya Quizizz)
  /// Mendukung RPC server online dan fallback evaluasi bank soal lokal/demo
  Future<QuizAnswerCheckResult> verifyQuestionAnswer({
    required String sessionId,
    required String questionId,
    required int selectedOption,
  }) async {
    final client = _getSupabaseClient();
    final user = client?.auth.currentUser;

    if (!AppConfig.isDemoMode && client != null && user != null && !sessionId.startsWith('demo-session-')) {
      try {
        final response = await client.rpc(
          'verify_quiz_question',
          params: {
            'p_session_id': sessionId,
            'p_question_id': questionId,
            'p_selected_option': selectedOption,
          },
        );

        if (response != null && response is Map) {
          final data = Map<String, dynamic>.from(response);
          return QuizAnswerCheckResult(
            isCorrect: data['is_correct'] as bool? ?? false,
            correctOption: (data['correct_option'] as num?)?.toInt() ?? -1,
            explanation: data['explanation'] as String? ?? '',
          );
        }
      } catch (e) {
        debugPrint('verifyQuestionAnswer server error: $e, beralih ke evaluasi lokal.');
      }
    }

    // Evaluasi lokal (Mode Demo / Offline / Fallback)
    final q = _mockQuestionsBank.firstWhere(
      (item) => item['id'] == questionId,
      orElse: () => _mockQuestionsBank.first,
    );

    final correctOpt = (q['correct_option'] as num?)?.toInt() ?? 0;
    final isCorrect = (selectedOption == correctOpt);

    return QuizAnswerCheckResult(
      isCorrect: isCorrect,
      correctOption: correctOpt,
      explanation: q['explanation'] as String? ?? '',
    );
  }

  /// Mendapatkan skor kuis tertinggi pengguna dari Hive terenkripsi
  int getBestQuizScore() {
    return EncryptedStorageService.instance.getBestQuizScore(defaultScore: 0);
  }

  // ============================================================================
  // DEMO & OFFLINE ENGINE (Plan 5.8)
  // Menjamin pengujian UI dan demo berjalan mulus saat offline
  // ============================================================================

  QuizSessionModel _startDemoQuizSession() {
    final rng = Random();
    final shuffled = List<Map<String, dynamic>>.from(_mockQuestionsBank)..shuffle(rng);
    final selected = shuffled.take(10).toList();

    // Hapus correct_option agar tidak pernah dikirim ke klien
    final clientQuestions = selected.map((q) {
      return QuizQuestionModel(
        id: q['id'] as String,
        category: q['category'] as String,
        question: q['question'] as String,
        options: List<String>.from(q['options'] as List),
      );
    }).toList();

    return QuizSessionModel(
      sessionId: 'demo-session-${DateTime.now().millisecondsSinceEpoch}',
      totalQuestions: clientQuestions.length,
      questions: clientQuestions,
    );
  }

  QuizResultModel _finishDemoQuizSession(String sessionId, List<QuizAnswerInput> answers) {
    int totalScore = 0;
    int correctCount = 0;
    int combo = 0;
    int maxCombo = 0;
    const basePoints = 100;
    const comboBonus = 25;

    final summary = <QuizAnswerSummaryItem>[];

    for (final ans in answers) {
      final qData = _mockQuestionsBank.firstWhere(
        (q) => q['id'] == ans.questionId,
        orElse: () => _mockQuestionsBank.first,
      );

      final correctOpt = qData['correct_option'] as int;
      final isCorrect = ans.selectedOption != null && ans.selectedOption == correctOpt;

      if (isCorrect) {
        correctCount++;
        combo++;
        if (combo > maxCombo) maxCombo = combo;

        int speedBonus = 0;
        if (ans.elapsedMs > 0 && ans.elapsedMs < 8000) {
          speedBonus = ((8000 - ans.elapsedMs) / 100).round();
        }

        totalScore += basePoints + (combo * comboBonus) + speedBonus;
      } else {
        combo = 0;
      }

      summary.add(
        QuizAnswerSummaryItem(
          questionId: ans.questionId,
          question: qData['question'] as String,
          selectedOption: ans.selectedOption,
          correctOption: correctOpt,
          isCorrect: isCorrect,
          explanation: qData['explanation'] as String,
        ),
      );
    }

    final oldBest = getBestQuizScore();
    final newBest = max(oldBest, totalScore);

    // Perbarui cache Hive
    EncryptedStorageService.instance.saveBestQuizScore(newBest);

    return QuizResultModel(
      sessionId: sessionId,
      score: totalScore,
      correctCount: correctCount,
      maxCombo: maxCombo,
      previousBest: oldBest,
      bestQuizScore: newBest,
      isNewBest: totalScore > oldBest,
      answersSummary: summary,
    );
  }

  static final List<Map<String, dynamic>> _mockQuestionsBank = [
    {
      'id': 'mock-q-01',
      'category': 'Aves',
      'question': 'Burung endemik Bali yang memiliki bulu putih bersih dan topeng biru di kelopak mata adalah...',
      'options': ['Cenderawasih Kuning', 'Jalak Bali', 'Maleo Senkawor', 'Kakatua Raja'],
      'correct_option': 1,
      'explanation': 'Jalak Bali (Leucopsar rothschildi) adalah burung endemik Bali Barat yang berstatus Kritis (CR).'
    },
    {
      'id': 'mock-q-02',
      'category': 'Reptilia',
      'question': 'Komodo (Varanus komodoensis) mendeteksi aroma bangkai dan mangsa dari kejauhan menggunakan...',
      'options': ['Telinga tengah', 'Organ Jacobson pada lidah bercabang', 'Mata faset malam', 'Sensor termal dagu'],
      'correct_option': 1,
      'explanation': 'Lidah bercabang Komodo menangkap molekul bau lalu mengantarkannya ke organ Jacobson di langit-langit mulut.'
    },
    {
      'id': 'mock-q-03',
      'category': 'Mamalia',
      'question': 'Orangutan Sumatera (Pongo abelii) memiliki ciri bulu khas dibanding Orangutan Kalimantan, yaitu...',
      'options': ['Bulu lebih lebat dan warna jingga terang', 'Tidak memiliki bulu pipi', 'Ekor sangat panjang', 'Berwarna cokelat kehitaman'],
      'correct_option': 0,
      'explanation': 'Orangutan Sumatera berbulu lebih panjang dan berwarna jingga lebih pucat dibanding saudaranya di Kalimantan.'
    },
    {
      'id': 'mock-q-04',
      'category': 'Biogeografi',
      'question': 'Garis khayal yang membatasi fauna tipe Asiatis dan tipe Peralihan di kepulauan Indonesia disebut...',
      'options': ['Garis Weber', 'Garis Wallace', 'Garis Lydekker', 'Garis Khatulistiwa'],
      'correct_option': 1,
      'explanation': 'Garis Wallace membentang antara Selat Lombok dan Selat Makassar, memisahkan fauna Asiatis dan Wallacea.'
    },
    {
      'id': 'mock-q-05',
      'category': 'Mamalia',
      'question': 'Anoa (Bubalus depressicornis) yang berpostur kerdil merupakan satwa endemik pulau...',
      'options': ['Sumatera', 'Kalimantan', 'Sulawesi', 'Papua'],
      'correct_option': 2,
      'explanation': 'Anoa adalah bovid liar terkecil di dunia yang hidup endemik di hutan pegunungan dan dataran rendah Pulau Sulawesi.'
    },
    {
      'id': 'mock-q-06',
      'category': 'Aves',
      'question': 'Burung Maleo (Macrocephalon maleo) meletakkan telurnya untuk ditetaskan menggunakan...',
      'options': ['Mengerami sendiri di dahan pohon', 'Pasir bersuhu panas bumi (geotermal)', 'Sarang liur di gua', 'Rongga tanah berair'],
      'correct_option': 1,
      'explanation': 'Maleo mengubur telurnya di pasir pantai berpanas bumi atau area geotermal Sulawesi agar menetas secara alami.'
    },
    {
      'id': 'mock-q-07',
      'category': 'Mamalia',
      'question': 'Badak Jawa (Rhinoceros sondaicus) memiliki perbedaan utama dengan Badak Sumatera yaitu...',
      'options': ['Memiliki satu cula (cula tunggal)', 'Memiliki dua cula panjang', 'Memiliki loreng di punggung', 'Tidak memiliki lipatan kulit'],
      'correct_option': 0,
      'explanation': 'Badak Jawa memiliki satu cula (monoceros), sedangkan Badak Sumatera memiliki dua cula.'
    },
    {
      'id': 'mock-q-08',
      'category': 'Konservasi',
      'question': 'Kategori status konservasi IUCN untuk spesies yang menghadapi risiko kepunahan amat tinggi di alam liar adalah...',
      'options': ['Least Concern (LC)', 'Vulnerable (VU)', 'Critically Endangered (CR)', 'Near Threatened (NT)'],
      'correct_option': 2,
      'explanation': 'Critically Endangered (Kritis) mengindikasikan spesies berada di ambang kepunahan dalam waktu amat dekat.'
    },
    {
      'id': 'mock-q-09',
      'category': 'Mamalia',
      'question': 'Bekantan (Nasalis larvatus) adalah monyet berhidung besar yang hidup di hutan mangrove pulau...',
      'options': ['Kalimantan', 'Jawa', 'Sumatera', 'Bali'],
      'correct_option': 0,
      'explanation': 'Bekantan adalah primata khas hutan rawa gambut dan bakau di Pulau Kalimantan.'
    },
    {
      'id': 'mock-q-10',
      'category': 'Reptilia',
      'question': 'Kura-kura Leher Ular Rote (Chelodina mccordi) memiliki ciri khas...',
      'options': ['Tempurung lunak transparan', 'Leher ditekuk ke samping (tidak ditarik lurus)', 'Bisa memanjat pohon mangrove', 'Bernapas dengan insang'],
      'correct_option': 1,
      'explanation': 'Kura-kura leher ular Rote melipat leher panjangnya ke samping di bawah tempurung (subordo Pleurodira).'
    },
    {
      'id': 'mock-q-11',
      'category': 'Mamalia',
      'question': 'Harimau Sumatera (Panthera tigris sumatrae) memiliki adaptasi tubuh berukuran ramping untuk...',
      'options': ['Berenang di samudra lepas', 'Menyusup di antara vegetasi rapat hutan hujan', 'Menggali liang di bawah tanah', 'Menahan dingin salju'],
      'correct_option': 1,
      'explanation': 'Ukuran tubuh yang lebih kecil dan loreng yang lebih rapat memudahkan Harimau Sumatera bermanuver di hutan lebat.'
    },
    {
      'id': 'mock-q-12',
      'category': 'Amfibi',
      'question': 'Katak Pohon Mutiara (Nyctixalus margaritifer) merupakan amfibi endemik Jawa dengan ciri...',
      'options': ['Bintik putih menyerupai mutiara di punggung', 'Ekor panjang menyerupai kadal', 'Tubuh bercahaya hijau di malam hari', 'Kaki berselaput tebal untuk berenang'],
      'correct_option': 0,
      'explanation': 'Nyctixalus margaritifer dinamai mutiara karena bintik-bintik putih menonjol di kulit cokelat kemerahannya.'
    },
  ];
}
