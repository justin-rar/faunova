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
    {
      'id': 'mock-q-13',
      'category': 'Mamalia',
      'question': 'Tarsius (Tarsius spectrumgurskyae) adalah primata karnivora terkecil yang matanya tidak dapat melirik, namun dapat memutar kepalanya hingga...',
      'options': ['180 derajat ke kiri dan ke kanan', '90 derajat total', '45 derajat saja', '360 derajat putaran penuh sekaligus'],
      'correct_option': 0,
      'explanation': 'Tarsius memiliki leher sangat fleksibel yang dapat berputar 180 derajat ke kiri maupun ke kanan untuk mengawasi mangsa di kegelapan malam.'
    },
    {
      'id': 'mock-q-14',
      'category': 'Mamalia',
      'question': 'Babirusa (Babyrousa babyrussa) adalah satwa unik endemik Sulawesi dengan ciri khas taring atas melengkung yang tumbuh menembus...',
      'options': ['Rahang bawah bagian depan', 'Gusi belakang geraham', 'Kulit moncong bagian atas', 'Tulang pelipis mata'],
      'correct_option': 2,
      'explanation': 'Pada Babirusa jantan, taring atas tumbuh mencuat menembus kulit moncong atas dan melengkung ke arah dahi.'
    },
    {
      'id': 'mock-q-15',
      'category': 'Mamalia',
      'question': 'Pesut Mahakam (Orcaella brevirostris) adalah mamalia lumba-lumba air tawar langka berstatus Kritis (CR) yang mendiami aliran sungai...',
      'options': ['Sungai Kapuas di Kalimantan Barat', 'Sungai Mahakam di Kalimantan Timur', 'Sungai Barito di Kalimantan Selatan', 'Sungai Musi di Sumatera Selatan'],
      'correct_option': 1,
      'explanation': 'Pesut Mahakam hidup di perairan tawar Sungai Mahakam, Kalimantan Timur, dan populasinya sangat rentan terancam kepunahan.'
    },
    {
      'id': 'mock-q-16',
      'category': 'Aves',
      'question': 'Kasuari Gelambir Ganda (Casuarius casuarius) dari Papua memiliki pertahanan kaki yang sangat berbahaya berupa...',
      'options': ['Sengatan racun di tumit', 'Cakar tengah lurus tajam menyerupai belati', 'Selaput renang keras bergerigi', 'Kelenjar getah perekat mangsa'],
      'correct_option': 1,
      'explanation': 'Jari kaki bagian dalam Kasuari dilengkapi cakar lurus tajam hingga 12 cm yang sangat mematikan saat menendang predator.'
    },
    {
      'id': 'mock-q-17',
      'category': 'Aves',
      'question': 'Elang Jawa (Nisaetus bartelsi) adalah burung pemangsa endemik Pulau Jawa yang menjadi figur inspirasi lambang nasional Indonesia yaitu...',
      'options': ['Burung Maleo', 'Cenderawasih Emas', 'Burung Garuda', 'Kakatua Putih'],
      'correct_option': 2,
      'explanation': 'Jambul khas dan corak Elang Jawa menjadikannya satwa langka yang diidentikkan dengan lambang negara Burung Garuda.'
    },
    {
      'id': 'mock-q-18',
      'category': 'Biogeografi',
      'question': 'Garis khayal yang membatasi fauna tipe Peralihan (Wallacea) dengan fauna tipe Australis di kawasan timur kepulauan Indonesia disebut...',
      'options': ['Garis Wallace', 'Garis Weber', 'Garis Lydekker', 'Garis Khatulistiwa'],
      'correct_option': 1,
      'explanation': 'Garis Weber menggambarkan batas persebaran fauna Australis dengan kawasan pulau peralihan Wallacea di Indonesia tengah.'
    },
    {
      'id': 'mock-q-19',
      'category': 'Ikan',
      'question': 'Coelacanth Sulawesi (Latimeria menadoensis) sering dijuluki "fosil hidup" karena morfologinya tidak banyak berubah sejak masa purba, ditemukan di perairan...',
      'options': ['Selat Sunda', 'Teluk Cenderawasih', 'Laut Jawa', 'Manado Tua, Sulawesi Utara'],
      'correct_option': 3,
      'explanation': 'Spesimen Coelacanth hidup ditemukan di perairan pulau vulkanik Manado Tua pada akhir dekade 1990-an.'
    },
    {
      'id': 'mock-q-20',
      'category': 'Mamalia',
      'question': 'Trenggiling Jawa (Manis javanica) melindungi dirinya dari ancaman predator dengan menggulung tubuh dan mengandalkan sisik keras berbahan...',
      'options': ['Keratin (protein penyusun kuku dan rambut)', 'Kalsium karbonat tempurung', 'Lapisan kitin exoskeleton', 'Serat kolagen bertulang rawan'],
      'correct_option': 0,
      'explanation': 'Sisik trenggiling tersusun dari keratin padat, bahan yang sama dengan kuku manusia dan tanduk badak, sangat kuat menahan gigitan predator.'
    },
    {
      'id': 'mock-q-21',
      'category': 'Aves',
      'question': 'Kakatua Raja (Probosciger aterrimus) memiliki ciri fisik unik burung kakatua hitam berukuran besar dari Papua yang paruhnya berfungsi memecah...',
      'options': ['Daging bangkai mamalia besar', 'Biji kenari keras dan kacang hutan berkayu', 'Cangkang kerang laut tebal', 'Kulit kura-kura sungai'],
      'correct_option': 1,
      'explanation': 'Paruh Kakatua Raja sangat kokoh dengan daya tekan besar untuk membuka biji kenari hutan yang berkulit amat tebal.'
    },
    {
      'id': 'mock-q-22',
      'category': 'Ikan',
      'question': 'Ikan Arwana Super Red (Scleropages formosus) yang terkenal bernilai tinggi di kalangan pehobi merupakan spesies endemik dari...',
      'options': ['Danau Toba, Sumatera Utara', 'Sungai Kapuas dan Danau Sentarum, Kalimantan Barat', 'Danau Matano, Sulawesi Selatan', 'Sungai Mamberamo, Papua'],
      'correct_option': 1,
      'explanation': 'Varietas Arwana Super Red asli hidup endemik di sistem perairan DAS Sungai Kapuas dan Danau Sentarum, Kalimantan Barat.'
    },
    {
      'id': 'mock-q-23',
      'category': 'Aves',
      'question': 'Burung Rangkong / Enggang Badak (Buceros rhinoceros) memiliki tonjolan mirip tanduk di atas paruhnya yang disebut casque, yang berfungsi untuk...',
      'options': ['Memperkeras resonansi suara panggilan dan atraksi kawin', 'Menyimpan cadangan air minum darurat', 'Mengikis tanah liat tebing', 'Menghasilkan racun pertahanan diri'],
      'correct_option': 0,
      'explanation': 'Casque berongga pada burung Rangkong berfungsi sebagai ruang resonansi akustik untuk memperkuat panggilan suara di hutan lebat.'
    },
    {
      'id': 'mock-q-24',
      'category': 'Mamalia',
      'question': 'Macan Dahan Kalimantan (Neofelis diardi) adalah kucing liar penghuni pohon (arboreal) yang memiliki proporsi taring...',
      'options': ['Terpendek di antara keluarga kucing', 'Paling rapuh dan tidak bergerigi', 'Terpanjang dibanding ukuran tengkoraknya di antara felidae hidup', 'Hanya tumbuh pada jantan dewasa'],
      'correct_option': 2,
      'explanation': 'Proporsi gigi taring Macan Dahan terhadap ukuran kepalanya adalah yang terpanjang di antara seluruh spesies kucing liar yang hidup.'
    },
    {
      'id': 'mock-q-25',
      'category': 'Mamalia',
      'question': 'Kanguru Pohon Wondiwoi (Dendrolagus mayri) adalah mamalia berkantung (marsupial) endemik Papua yang hidup di...',
      'options': ['Rawa bakau pantai air payau', 'Tajuk pepohonan hutan pegunungan tinggi', 'Gua-gua kapur bawah tanah', 'Padang rumput terbuka dataran rendah'],
      'correct_option': 1,
      'explanation': 'Kanguru pohon beradaptasi dengan kaki depan yang kuat dan ekor panjang untuk memanjat di antara tajuk pohon hutan pegunungan Papua.'
    },
    {
      'id': 'mock-q-26',
      'category': 'Reptilia',
      'question': 'Kura-kura Moncong Babi (Carettochelys insculpta) memiliki hidung berdaging fleksibel menyerupai babi yang berguna untuk...',
      'options': ['Snorkel mengambil udara saat tubuh terkubur di lumpur sungai', 'Alat penyengat mangsa berdaya listrik', 'Menggali lubang sarang di bebatuan keras', 'Menghasilkan bau penolak buaya'],
      'correct_option': 0,
      'explanation': 'Moncong panjang seperti snorkel memungkinkan kura-kura ini bernapas di permukaan air saat tubuhnya tersembunyi di dasar lumpur.'
    },
    {
      'id': 'mock-q-27',
      'category': 'Amfibi',
      'question': 'Katak Terbang Jawa (Rhacophorus reinwardtii) dapat melayang meluncur dari satu dahan ke dahan lain menggunakan...',
      'options': ['Selaput lebar di antara jari-jari kaki dan lipatan kulit paha', 'Sayap berbulu halus di bagian dada', 'Ekor panjang berotot kuat', 'Kantung udara di bawah tenggorokan'],
      'correct_option': 0,
      'explanation': 'Selaput kaki lebar berfungsi layaknya parasut kecil sehingga katak pohon ini mampu meluncur di udara hingga puluhan meter.'
    },
    {
      'id': 'mock-q-28',
      'category': 'Mamalia',
      'question': 'Banteng Jawa (Bos javanicus) memiliki penanda visual khas yang paling mudah dikenali di alam liar berupa...',
      'options': ['Garis loreng hitam di punggung', 'Tanduk yang selalu bercabang tiga', 'Bercak putih bundar seperti cermin di bagian pantat', 'Bulu leher lebat seperti surai singa'],
      'correct_option': 2,
      'explanation': 'Banteng Jawa memiliki warna putih kontras pada pantat (rump patch) serta pola kaos kaki putih di keempat kakinya.'
    },
    {
      'id': 'mock-q-29',
      'category': 'Mamalia',
      'question': 'Kuskus Beruang Sulawesi (Ailurops ursinus) adalah hewan marsupial kanopi hutan Sulawesi yang bergerak lambat dan beraktivitas saat...',
      'options': ['Hanya saat fajar menyingsing', 'Siang hari (diurnal) dengan memakan dedaunan muda', 'Malam hari di dasar tanah', 'Tidur selama 6 bulan di musim kemarau'],
      'correct_option': 1,
      'explanation': 'Berbeda dengan kuskus lain yang nokturnal, Kuskus Beruang aktif di siang hari memakan daun-daun muda di kanopi hutan.'
    },
    {
      'id': 'mock-q-30',
      'category': 'Aves',
      'question': 'Cenderawasih Merah (Paradisaea rubra) yang memiliki sepasang bulu kawat ekor ganda melengkung merupakan satwa endemik pulau...',
      'options': ['Waigeo dan Batanta di Kepulauan Raja Ampat', 'Pulau Bali bagian barat', 'Pulau Sumba di Nusa Tenggara', 'Kepulauan Mentawai di barat Sumatera'],
      'correct_option': 0,
      'explanation': 'Cenderawasih Merah hanya hidup secara endemik di hutan Pulau Waigeo dan Batanta, Raja Ampat, Papua Barat Daya.'
    },
    {
      'id': 'mock-q-31',
      'category': 'Reptilia',
      'question': 'Buaya Muara (Crocodylus porosus) dikenal sebagai reptil hidup terbesar di bumi yang memiliki adaptasi kelenjar garam khusus di lidahnya untuk...',
      'options': ['Mendeteksi getaran gelombang sonar', 'Mengeluarkan kelebihan garam sehingga bisa berenang jauh di laut lepas', 'Menghasilkan bisa neurotoksin beracun', 'Memecah cangkang penyu laut'],
      'correct_option': 1,
      'explanation': 'Kelenjar garam lingual membantu buaya muara berenang melintasi selat dan samudra antar-pulau.'
    },
    {
      'id': 'mock-q-32',
      'category': 'Konservasi',
      'question': 'Taman Nasional Ujung Kulon yang terletak di provinsi Banten merupakan benteng pertahanan terakhir di dunia bagi satwa langka...',
      'options': ['Gajah Kerdil Borneo', 'Badak Jawa (Rhinoceros sondaicus)', 'Harimau Bali', 'Orangutan Tapanuli'],
      'correct_option': 1,
      'explanation': 'Taman Nasional Ujung Kulon adalah satu-satunya habitat alami yang tersisa di planet bumi bagi populasi liar Badak Jawa.'
    },
    {
      'id': 'mock-q-33',
      'category': 'Reptilia',
      'question': 'Biawak Pohon Biru (Varanus macraei) adalah kadal pemanjat yang memiliki pola sisik biru pirus cerah dengan ekor prehensil, endemik pulau...',
      'options': ['Pulau Batanta, Kepulauan Raja Ampat', 'Pulau Komodo, NTT', 'Pulau Nias, Sumatera', 'Pulau Madura, Jawa Timur'],
      'correct_option': 0,
      'explanation': 'Varanus macraei ditemukan pertama kali pada tahun 2001 di Pulau Batanta, Raja Ampat, dan mahir memanjat pohon menggunakan ekornya.'
    },
    {
      'id': 'mock-q-34',
      'category': 'Mamalia',
      'question': 'Gajah Sumatera (Elephas maximus sumatranus) memiliki ciri pembeda fisik dengan Gajah Afrika, di antaranya adalah...',
      'options': ['Telinga berukuran lebih kecil dan memiliki dua tonjolan di dahi', 'Tidak pernah memiliki gading pada jantan', 'Memiliki bulu lebat di sekujur tubuh', 'Memiliki dua lubang belalai terpisah'],
      'correct_option': 0,
      'explanation': 'Gajah Sumatera memiliki daun telinga yang jauh lebih kecil daripada Gajah Afrika dan punggung yang berbentuk melengkung cembung.'
    },
    {
      'id': 'mock-q-35',
      'category': 'Reptilia',
      'question': 'Penyu Belimbing (Dermochelys coriacea) adalah penyu laut terbesar di dunia yang memiliki keunikan fisik tempurung berupa...',
      'options': ['Karapas bertanduk runcing seperti duri landak', 'Karapas lunak menyerupai kulit tebal kenyal tanpa sisik keras', 'Tempurung tembus pandang berbahan kalsium cair', 'Tempurung berbentuk bola bulat sempurna'],
      'correct_option': 1,
      'explanation': 'Penyu Belimbing memiliki karapas berbahan kulit tebal kenyal fleksibel dengan 7 lunas membujur.'
    },
    {
      'id': 'mock-q-36',
      'category': 'Konservasi',
      'question': 'Dalam konvensi perdagangan satwa liar internasional CITES, spesies yang masuk dalam daftar "Appendix I" memiliki arti...',
      'options': ['Bebas diperjualbelikan antarnegara tanpa izin resmi', 'Terancam punah dan dilarang keras untuk perdagangan komersial internasional', 'Populasinya sangat melimpah dan boleh diburu', 'Hanya berlaku untuk satwa peliharaan domestik'],
      'correct_option': 1,
      'explanation': 'Appendix I mencakup spesies satwa liar paling terancam punah yang dilarang keras untuk diperdagangkan secara komersial.'
    },
    {
      'id': 'mock-q-37',
      'category': 'Mamalia',
      'question': 'Rusa Bawean (Axis kuhlii) adalah spesies rusa berpostur pendek dengan tanduk bercabang tiga yang hidup secara endemik terbatas di...',
      'options': ['Pulau Bawean di perairan Laut Jawa', 'Pulau Weh di ujung Aceh', 'Pulau Karimunjawa di Jawa Tengah', 'Pulau Maratua di Kalimantan Timur'],
      'correct_option': 0,
      'explanation': 'Rusa Bawean berstatus Kritis (CR) dan hanya hidup di perbukitan Pulau Bawean, sekitar 120 km utara Gresik, Jawa Timur.'
    },
    {
      'id': 'mock-q-38',
      'category': 'Reptilia',
      'question': 'Tokek dan cecak mampu menempel kuat di permukaan kaca atau dinding vertikal berkat jutaan rambut halus mikro di telapak kakinya yang memanfaatkan gaya...',
      'options': ['Gaya magnetik statis bumi', 'Gaya molekuler Van der Waals', 'Lapisan lem cairan beracun', 'Tekanan vakum penyedot udara'],
      'correct_option': 1,
      'explanation': 'Spatulae mikroskopis pada telapak kaki tokek menghasilkan interaksi molekuler gaya Van der Waals dengan permukaan dinding.'
    },
    {
      'id': 'mock-q-39',
      'category': 'Konservasi',
      'question': 'Taman Nasional Lorentz yang merupakan taman nasional terluas di Asia Tenggara dan diakui sebagai Situs Warisan Dunia UNESCO terletak di kepulauan...',
      'options': ['Sulawesi bagian selatan', 'Sumatera bagian barat', 'Kalimantan bagian timur', 'Papua (membentang dari Puncak Carstensz hingga pesisir)'],
      'correct_option': 3,
      'explanation': 'Taman Nasional Lorentz di Papua memiliki rentang ekosistem terlengkap di kawasan Pasifik dari gletser salju abadi hingga pesisir tropis.'
    },
    {
      'id': 'mock-q-40',
      'category': 'Aves',
      'question': 'Burung Maleo (Macrocephalon maleo) memiliki benjolan tanduk hitam keras di atas kepalanya yang diyakini para ahli berfungsi sebagai...',
      'options': ['Sensor pendeteksi suhu pasir geotermal tempat bertelur', 'Senjata mematikan untuk berburu serangga', 'Kantung penyimpan makanan cadangan', 'Alat penampung air hujan saat badai'],
      'correct_option': 0,
      'explanation': 'Benjolan di kepala Maleo diyakini membantu burung mendeteksi panas bumi pasir vulkanik yang pas untuk menetaskan telurnya.'
    },
    {
      'id': 'mock-q-41',
      'category': 'Mamalia',
      'question': 'Kukang Jawa (Nycticebus javanicus) adalah satu-satunya primata berbisa di dunia yang mengeluarkan cairan bisa berbahaya dari...',
      'options': ['Kelenjar brakial di lipatan siku bagian dalam', 'Kantung khusus di bawah lidah', 'Ujung kuku jemari kaki belakang', 'Kelenjar aroma di ekor'],
      'correct_option': 0,
      'explanation': 'Kukang menjilat kelenjar brakial di sikunya lalu mencampurnya dengan air liur untuk menghasilkan gigitan berbisa mematikan.'
    },
    {
      'id': 'mock-q-42',
      'category': 'Mamalia',
      'question': 'Lutung Jawa (Trachypithecus auratus) yang baru lahir memiliki keunikan fisik yang sangat mencolok dibanding induknya yang hitam pekat yaitu...',
      'options': ['Bulu berwarna oranye keemasan terang benderang', 'Tidak memiliki ekor sama sekali', 'Memiliki cakar tajam seperti kucing', 'Tubuh bercahaya di malam hari'],
      'correct_option': 0,
      'explanation': 'Bayi Lutung Jawa lahir dengan bulu berwarna oranye terang mencolok agar mudah diawasi oleh kawanan di rimbunnya hutan.'
    },
    {
      'id': 'mock-q-43',
      'category': 'Mamalia',
      'question': 'Tapir Asia (Tapirus indicus) memiliki corak warna dua warna (hitam dan pelana putih di punggung) yang berfungsi sebagai...',
      'options': ['Kamuflase disrupsi visual pemecah siluet di malam hari', 'Penyerap radiasi sinar matahari siang', 'Penolak gigitan nyamuk hutan lebat', 'Penanda hierarki kepemimpinan kawanan'],
      'correct_option': 0,
      'explanation': 'Pola hitam-putih kontras memecah siluet tubuh tapir di bawah sinar rembulan di hutan sehingga predator sulit mengenali bentuk tubuhnya.'
    },
    {
      'id': 'mock-q-44',
      'category': 'Biota Laut',
      'question': 'Pari Manta Karang (Mobula alfredi) memiliki corak bintik hitam unik di bagian perutnya yang dimanfaatkan para peneliti untuk...',
      'options': ['Identifikasi individu satwa menyerupai sidik jari manusia', 'Menghasilkan sengatan listrik pertahanan diri', 'Menarik perhatian mangsa ikan kecil', 'Menentukan perkiraan umur tulang ikan'],
      'correct_option': 0,
      'explanation': 'Pola bintik di perut Pari Manta bersifat permanen dan unik untuk setiap individu, menjadi dasar metode foto-identifikasi populasi di alam.'
    },
    {
      'id': 'mock-q-45',
      'category': 'Mamalia',
      'question': 'Kucing Batu (Pardofelis marmorata) adalah kucing liar arboreal Indonesia yang memiliki adaptasi ekor sangat khas yaitu...',
      'options': ['Sangat panjang dan tebal berotot untuk keseimbangan di dahan', 'Sangat pendek seperti ekor kelinci', 'Bergerigi tajam untuk mencengkeram ranting', 'Berwarna putih polos tanpa corak'],
      'correct_option': 0,
      'explanation': 'Ekor Kucing Batu panjangnya menyamai panjang tubuhnya dan berfungsi sebagai penyeimbang sempurna saat melompat di tajuk pohon tinggi.'
    },
    {
      'id': 'mock-q-46',
      'category': 'Aves',
      'question': 'Burung Paok Bergaris (Pitta guajana) adalah burung endemik lantai hutan Jawa yang mencari makan berupa cacing dan serangga di antara...',
      'options': ['Seresah tumpukan daun kering lantai hutan', 'Tajuk puncak tertinggi pohon beringin', 'Batang pohon pinus berlumut', 'Bebatuan licin dasar air terjun'],
      'correct_option': 0,
      'explanation': 'Burung Paok banyak menghabiskan waktu melompat-lompat di lantai hutan yang lembap untuk membongkar seresah daun mencari mangsa.'
    },
    {
      'id': 'mock-q-47',
      'category': 'Reptilia',
      'question': 'Tuntong Laut (Batagur borneoensis) jantan dewasa mengalami perubahan warna dramatis saat musim kawin berupa...',
      'options': ['Warna kepala berubah putih terang dengan garis merah di antara mata', 'Tempurung berubah hijau cerah bercahaya', 'Leher memanjang dua kali ukuran semula', 'Kaki berubah keemasan mengilap'],
      'correct_option': 0,
      'explanation': 'Perubahan warna kepala Tuntong jantan menjadi putih mencolok dengan corak merah terang berfungsi sebagai sinyal visual memikat betina.'
    },
    {
      'id': 'mock-q-48',
      'category': 'Biota Laut',
      'question': 'Hiu Paus (Rhincodon typus) yang sering dijumpai di perairan Gorontalo dan Papua adalah ikan terbesar di dunia yang memakan...',
      'options': ['Plankton dan ikan kecil melalui tapis insang', 'Bangkai mamalia paus besar', 'Singa laut dan penyu dewasa', 'Terumbu karang dan rumput laut'],
      'correct_option': 0,
      'explanation': 'Hiu Paus adalah pemakan saring (filter feeder) yang tidak memangsa satwa besar melainkan menyaring plankton di permukaan air.'
    },
    {
      'id': 'mock-q-49',
      'category': 'Invertebrata',
      'question': 'Laba-laba Pelompat (Salticidae) memiliki sepasang mata utama depan berukuran sangat besar yang memungkinkannya...',
      'options': ['Melihat warna dan memiliki persepsi kedalaman 3D yang sangat tajam', 'Melihat dalam kegelapan total tanpa cahaya', 'Menembakkan racun dari kejauhan', 'Mendeteksi gelombang radio mangsa'],
      'correct_option': 0,
      'explanation': 'Laba-laba pelompat memiliki ketajaman visual terbaik di antara semua arthropoda untuk memperhitungkan jarak lompatan saat menerkam.'
    },
    {
      'id': 'mock-q-50',
      'category': 'Aves',
      'question': 'Burung Kacamata Wangi-wangi (Zosterops flavissimus) adalah burung endemik Kepulauan Wakatobi dengan ciri khas...',
      'options': ['Lingkaran bulu putih halus melingkar di sekeliling matanya', 'Ekor kaku melengkung berbentuk sabit', 'Paruh bergerigi pemakan ikan kecil', 'Jambul merah jambu di dahi'],
      'correct_option': 0,
      'explanation': 'Ciri utama genus Zosterops adalah cincin kacamata putih bersih yang mengelilingi bola mata.'
    },
    {
      'id': 'mock-q-51',
      'category': 'Aves',
      'question': 'Burung Kasuari di Papua selain dapat berlari kencang di daratan juga memiliki kemampuan fisik yang jarang diketahui yaitu...',
      'options': ['Mampu berenang dengan lincah menyeberangi sungai lebar dan teluk laut', 'Mampu terbang melayang rendah di malam hari', 'Mampu memanjat pohon kelapa menggunakan sayap', 'Bisa menggali terowongan bawah tanah'],
      'correct_option': 0,
      'explanation': 'Kasuari adalah perenang yang sangat andal dan sering terlihat menyeberangi sungai deras atau perairan pesisir di Papua.'
    },
    {
      'id': 'mock-q-52',
      'category': 'Reptilia',
      'question': 'Komodo (Varanus komodoensis) membunuh mangsa berukuran besar seperti kerbau dan rusa dengan mengandalkan gigitan yang mengandung...',
      'options': ['Kelenjar bisa antikoagulan yang mencegah pembekuan darah', 'Bisa hemotoksin penembus tulang', 'Bisa neurotoksin penyengat saraf seketika', 'Zat asam korosif penghancur kulit'],
      'correct_option': 0,
      'explanation': 'Komodo memiliki kelenjar bisa di rahang bawah yang mengeluarkan senyawa racun antikoagulan yang menurunkan tekanan darah mangsa.'
    },
    {
      'id': 'mock-q-53',
      'category': 'Mamalia',
      'question': 'Gajah Kerdil Borneo (Elephas maximus borneensis) memiliki ciri morfologis khas dibanding gajah Asia lainnya yaitu...',
      'options': ['Ekor sangat panjang yang menyentuh tanah dan gading lebih lurus', 'Telinga dua kali lebih lebar dari gajah Afrika', 'Memiliki dua punuk lemak di punggung', 'Tidak pernah memiliki rambut sama sekali'],
      'correct_option': 0,
      'explanation': 'Gajah Kerdil Kalimantan memiliki postur membulat, ekor panjang menjuntai hingga tanah, dan temperamen lebih ramah.'
    },
    {
      'id': 'mock-q-54',
      'category': 'Ikan',
      'question': 'Ikan Arwana Asia (Scleropages formosus) memiliki sepasang sungut (barbel) di ujung bibir bawahnya yang berguna untuk...',
      'options': ['Mendeteksi riak getaran mangsa di permukaan air', 'Menghasilkan sengatan listrik pertahanan', 'Bernapas mengambil udara di musim kemarau', 'Mengaitkan tubuh di celah bebatuan arus deras'],
      'correct_option': 0,
      'explanation': 'Sungut Arwana merupakan organ sensorik mekanoreseptor sensitif untuk mendeteksi mangsa yang jatuh di permukaan air.'
    },
    {
      'id': 'mock-q-55',
      'category': 'Reptilia',
      'question': 'Kura-kura Hutan Sulawesi (Leucocephalon yuwonoi) jantan dewasa memiliki ciri unik pada kepalanya berupa...',
      'options': ['Warna kepala memutih kontras menyerupai tengkorak', 'Tanduk bercabang tiga di atas hidung', 'Kantung kulit yang bisa mengembang di dagu', 'Mata merah menyala di kegelapan'],
      'correct_option': 0,
      'explanation': 'Jantan dewasa spesies langka ini memiliki kepala berwarna kuning pucat keputihan yang sangat kontras dengan leher dan tubuhnya.'
    },
    {
      'id': 'mock-q-56',
      'category': 'Invertebrata',
      'question': 'Kupu-kupu Sayap Burung Peri (Ornithoptera chimaera) adalah spesies kupu-kupu raksasa dengan sayap hijau keemasan yang hidup di dataran tinggi pulau...',
      'options': ['Papua', 'Jawa', 'Sumatera', 'Nusa Tenggara'],
      'correct_option': 0,
      'explanation': 'Genus Ornithoptera adalah kupu-kupu megah yang hidup di hutan pegunungan Pulau Papua dan dilindungi undang-undang.'
    },
    {
      'id': 'mock-q-57',
      'category': 'Mamalia',
      'question': 'Siamang (Symphalangus syndactylus) di hutan Sumatera memiliki kantung tenggorokan besar (gular sac) yang berfungsi untuk...',
      'options': ['Menghasilkan resonansi suara panggilan duet yang terdengar hingga 2 km', 'Menyimpan cadangan buah dan air', 'Menghangatkan tubuh saat suhu dingin', 'Mengembangkan tubuh untuk menakut-nakuti macan'],
      'correct_option': 0,
      'explanation': 'Kantung gular dapat mengembang seukuran kepala siamang untuk memperkeras resonansi suara panggilan melintasi kanopi hutan.'
    },
    {
      'id': 'mock-q-58',
      'category': 'Mamalia',
      'question': 'Pesut Mahakam memiliki bentuk kepala yang berbeda dari lumba-lumba laut pada umumnya, yaitu...',
      'options': ['Membulat tumpul tanpa moncong paruh yang memanjang', 'Moncong sangat panjang menyerupai paruh burung', 'Memiliki cula tajam di atas dahi', 'Pipih melebar menyerupai ikan pari'],
      'correct_option': 0,
      'explanation': 'Pesut Mahakam memiliki dahi membulat tinggi (melon) dan tidak memiliki moncong panjang khas lumba-lumba laut.'
    },
    {
      'id': 'mock-q-59',
      'category': 'Konservasi',
      'question': 'Taman Nasional Komodo yang dibentuk pada tahun 1980 melindungi habitat alami biawak purba Komodo di kepulauan...',
      'options': ['Pulau Komodo, Rinca, Padar, Gili Motang, dan Nusa Kode', 'Kepulauan Mentawai dan Nias', 'Kepulauan Karimunjawa dan Bawean', 'Kepulauan Derawan dan Maratua'],
      'correct_option': 0,
      'explanation': 'Taman Nasional Komodo mencakup gugusan Pulau Komodo, Rinca, Padar serta puluhan pulau kecil di Selat Sape, NTT.'
    },
    {
      'id': 'mock-q-60',
      'category': 'Reptilia',
      'question': 'Bunglon Sisir (Gonocephalus chamaeleontinus) mengandalkan pertahanan utama dari ancaman predator hutan berupa...',
      'options': ['Kamuflase mimikri menyatu sempurna dengan lumut dan kulit kayu', 'Bisa gigitan neurotoksik mematikan', 'Kemampuan memutuskan ekor berulang kali', 'Lompatan jauh di atas permukaan air'],
      'correct_option': 0,
      'explanation': 'Kadal bermahkota sisir ini memiliki pola warna dan tekstur kulit kasar yang meniru lumut dan kulit pohon hutan hujan tropis.'
    },
  ];

  /// Membuat dan menambahkan soal kuis baru secara dinamis saat satwa berhasil diidentifikasi AI (Crowdsourced Quiz Bank)
  Future<int> generateDynamicQuestionsForAnimal({
    required String animalName,
    required String speciesName,
    String? category,
    String? description,
    String? additionalFact,
  }) async {
    final client = _getSupabaseClient();
    final user = client?.auth.currentUser;

    final firstGenus = speciesName.trim().split(' ').first;

    // Paket 5 soal ilmiah otomatis seputar satwa yang baru saja difoto
    final generatedQuestions = [
      {
        'category': category ?? 'Fauna',
        'question': 'Satwa "$animalName" ($speciesName) diklasifikasikan ke dalam taksonomi genus...',
        'options': [
          firstGenus,
          'Panthera',
          'Varanus',
          'Macaca',
        ],
        'correct_option': 0,
        'explanation': '$animalName diklasifikasikan ke dalam genus $firstGenus.',
      },
      {
        'category': category ?? 'Fauna',
        'question': 'Berdasarkan pengamatan lapangan, adaptasi utama satwa "$animalName" ($speciesName) adalah...',
        'options': [
          description?.isNotEmpty == true ? description! : 'Beradaptasi secara alami pada ekosistem hutan tropis Indonesia.',
          'Hidup di kutub es tanpa vegetasi tanaman.',
          'Hanya mengonsumsi bebatuan vulkanik kering.',
          'Memiliki sayap berselaput untuk menyelam di palung laut.',
        ],
        'correct_option': 0,
        'explanation': '$animalName: ${description ?? 'Satwa khas ekosistem nusantara.'}',
      },
      {
        'category': 'Konservasi',
        'question': 'Fakta unik biologi mengenai satwa "$animalName" di alam liar adalah...',
        'options': [
          additionalFact?.isNotEmpty == true ? additionalFact! : 'Memiliki peran penting menjaga keseimbangan rantai makanan habitat aslinya.',
          'Dapat memancarkan sinar laser saat musim kemarau.',
          'Tidak memerlukan air minum sepanjang masa hidupnya.',
          'Dapat terbang melintasi samudra dalam hitungan menit.',
        ],
        'correct_option': 0,
        'explanation': additionalFact ?? 'Satwa ini memiliki peranan penting dalam keanekaragaman hayati.',
      },
      {
        'category': category ?? 'Fauna',
        'question': 'Di habitat alaminya, satwa "$animalName" berfungsi penting menjaga kelestarian alam sebagai...',
        'options': [
          'Bagian dari rantai makanan dan keseimbangan biodiversitas ekosistem',
          'Hama perusak mutlak yang harus dimusnahkan',
          'Parasit mematikan bagi semua pohon hutan',
          'Satwa pengganggu tanpa peranan ekologis',
        ],
        'correct_option': 0,
        'explanation': 'Setiap satwa seperti $animalName memiliki peran spesifik menjaga kelangsungan ekosistem alam.',
      },
      {
        'category': 'Taksonomi',
        'question': 'Nama ilmiah binomial resmi yang diakui dalam zoologi internasional untuk "$animalName" adalah...',
        'options': [
          speciesName,
          'Canis lupus familiaris',
          'Felis catus domesticus',
          'Gallus gallus domesticus',
        ],
        'correct_option': 0,
        'explanation': 'Tata nama ilmiah resmi untuk satwa $animalName adalah $speciesName.',
      },
    ];

    // 1. Simpan ke database Supabase jika online (tabel public.quiz_questions)
    if (client != null && user != null && !AppConfig.isDemoMode) {
      try {
        final toInsert = generatedQuestions.map((q) => {
          'category': q['category'],
          'question': q['question'],
          'options': q['options'],
          'correct_option': q['correct_option'],
          'explanation': q['explanation'],
          'is_active': true,
        }).toList();

        await client.from('quiz_questions').upsert(
          toInsert,
          onConflict: 'question',
          ignoreDuplicates: true,
        );
        debugPrint('Sukses menyuntikkan ${generatedQuestions.length} soal kuis AI baru untuk satwa $animalName ke server.');
      } catch (e) {
        debugPrint('Catatan: Gagal menyimpan soal dinamis ke Supabase: $e');
      }
    }

    // 2. Simpan juga ke bank memori lokal aplikasi agar bisa dimainkan langsung
    int addedCount = 0;
    for (final q in generatedQuestions) {
      final exists = _mockQuestionsBank.any((existing) => existing['question'] == q['question']);
      if (!exists) {
        _mockQuestionsBank.add({
          'id': 'dynamic-q-${DateTime.now().millisecondsSinceEpoch}-$addedCount',
          'category': q['category'],
          'question': q['question'],
          'options': q['options'],
          'correct_option': q['correct_option'],
          'explanation': q['explanation'],
        });
        addedCount++;
      }
    }

    return addedCount;
  }
}

