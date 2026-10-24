import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/services/shake_service.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/services/timezone_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../models/daily_challenge_model.dart';
import '../models/shake_quiz_model.dart';
import '../models/streak_status_model.dart';
import 'quiz_arena_page.dart';
import 'widgets/shake_quiz_sheet.dart';

class GamePage extends StatefulWidget {
  final bool isActive;
  const GamePage({super.key, this.isActive = true});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  AppViewStatus _currentStatus = AppViewStatus.content;
  bool _isStartingQuiz = false;

  StreakStatusModel? _streakStatus;
  DailyChallengeModel? _dailyChallenge;
  ShakeQuotaModel? _shakeQuota;
  StreamSubscription? _shakeSubscription;
  bool _isClaimingStreak = false;
  bool _isSubmittingChallenge = false;
  bool _isClaimingShake = false;

  @override
  void initState() {
    super.initState();
    _loadGameData();
    if (widget.isActive) {
      _initShakeSensor();
    }
  }

  @override
  void didUpdateWidget(covariant GamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _initShakeSensor();
      } else {
        _pauseShakeSensor();
      }
    }
  }

  @override
  void dispose() {
    _pauseShakeSensor();
    super.dispose();
  }

  void _initShakeSensor() {
    // Listener accelerometer hanya aktif saat membuka tab Game (Plan 191)
    if (_shakeSubscription != null) return;
    _shakeSubscription = ShakeService.instance.listenToShakeEvents(
      onShakeDetected: _handleShakeTriggered,
    );
  }

  void _pauseShakeSensor() {
    _shakeSubscription?.cancel();
    _shakeSubscription = null;
  }

  Future<void> _loadGameData() async {
    try {
      final streak = await StreakService.instance.getStreakStatus();
      final challenge = await StreakService.instance.getDailyChallenge();
      final quota = await ShakeService.instance.getShakeQuota();
      if (mounted) {
        setState(() {
          _streakStatus = streak;
          _dailyChallenge = challenge;
          _shakeQuota = quota;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleShakeTriggered() async {
    if (_isClaimingShake) return;
    setState(() => _isClaimingShake = true);

    try {
      final quota = _shakeQuota ?? await ShakeService.instance.getShakeQuota();
      if (quota.remainingQuota <= 0) {
        if (mounted) {
          setState(() => _isClaimingShake = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kuota goyang HP harian kamu sudah habis (3/3). Reset 00:00 WIB.'),
              backgroundColor: AppColors.merahStatus,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final claim = await ShakeService.instance.claimShakeQuiz();
      if (mounted) {
        setState(() => _isClaimingShake = false);
        if (claim.quotaExceeded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(claim.message),
              backgroundColor: AppColors.merahStatus,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadGameData();
          return;
        }

        // Tampilkan modal soal kejutan goyang HP
        _pauseShakeSensor();
        await ShakeQuizSheet.show(
          context,
          claim: claim,
          onQuizFinished: () {
            _loadGameData();
          },
        );
        if (mounted && widget.isActive) {
          _initShakeSensor();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClaimingShake = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat kuis goyang HP: $e'),
            backgroundColor: AppColors.merahStatus,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleClaimStreak() async {
    if (_isClaimingStreak) return;
    setState(() => _isClaimingStreak = true);

    try {
      final res = await StreakService.instance.claimDailyStreak();
      if (mounted) {
        setState(() {
          _streakStatus = res;
          _isClaimingStreak = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty ? res.message : 'Streak berhasil diklaim!'),
            backgroundColor: AppColors.sageTua,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClaimingStreak = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal check-in streak: $e'),
            backgroundColor: AppColors.merahStatus,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleAnswerDailyChallenge(int selectedOption) async {
    if (_isSubmittingChallenge) return;
    setState(() => _isSubmittingChallenge = true);

    try {
      final res = await StreakService.instance.answerDailyChallenge(selectedOption);
      if (mounted) {
        setState(() {
          _dailyChallenge = res;
          _isSubmittingChallenge = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: res.isCorrect == true ? AppColors.sageTua : AppColors.merahStatus,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingChallenge = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim jawaban: $e'),
            backgroundColor: AppColors.merahStatus,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleStartQuiz() async {
    setState(() => _isStartingQuiz = true);
    try {
      final session = await QuizService.instance.startQuizSession();
      if (mounted) {
        setState(() => _isStartingQuiz = false);
        _pauseShakeSensor();
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => QuizArenaPage(session: session)),
        );
        if (mounted && widget.isActive) {
          _initShakeSensor();
        }
        setState(() {}); // refresh best score
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStartingQuiz = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai kuis: $e'),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 14;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        centerTitle: true,
        title: Text(
          'Ekspedisi & Kuis Fauna',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16.5,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: AppStateView(
        status: _currentStatus,
        loadingMessage: 'Menyiapkan bank soal dan status streak server...',
        emptyTitle: 'Sesi Belum Tersedia',
        emptyMessage: 'Tidak ada sesi kuis aktif saat ini. Tantangan baru diperbarui setiap 00:00 WIB.',
        errorMessage: 'Gagal menghubungkan ke server game. Periksa sambungan data.',
        offlineMessage: 'Mode luring. Kuis dengan skor tervalidasi server memerlukan internet.',
        onRetry: () {
          setState(() {
            _currentStatus = AppViewStatus.content;
          });
          _loadGameData();
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 110),
          children: [
            _buildStateSwitcherCard(),
            const SizedBox(height: 14),

            // 1. Streak Card with Day Dots
            _buildStreakTrackerCard(),
            const SizedBox(height: 14),

            // 2. Tantangan Hari Ini Card
            _buildDailyChallengeCard(),
            const SizedBox(height: 14),

            // 3. Kuis Utama (10 Soal, Timer 15 Detik, 3 Nyawa)
            _buildQuizArenaCard(),
            const SizedBox(height: 14),

            // 4. Shake-to-Quiz Sensor Banner (Quota 3x/hari)
            _buildShakeToQuizBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildStateSwitcherCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: AppColors.teksGelap),
              SizedBox(width: 8),
              Text(
                'Simulasi State (AGENTS.md)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildStateChip('Normal', AppViewStatus.content),
              _buildStateChip('Memuat', AppViewStatus.loading),
              _buildStateChip('Kosong', AppViewStatus.empty),
              _buildStateChip('Galat', AppViewStatus.error),
              _buildStateChip('Luring', AppViewStatus.offline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateChip(String label, AppViewStatus status) {
    final isSelected = _currentStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _currentStatus = status;
        });
      },
      selectedColor: AppColors.sageTua,
      backgroundColor: AppColors.gading,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.teksPutih : AppColors.teksGelap,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStreakTrackerCard() {
    final streak = _streakStatus?.streakCount ?? 5;
    final isClaimed = _streakStatus?.isClaimedToday ?? false;
    final currentWibWeekday = TimeZoneService.getCurrentDateWib().weekday; // 1 = Mon, 7 = Sun

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.sageTua,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.teksPutih,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Streak Observasi Harian',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    Text(
                      '$streak Hari Berturut-turut 🔥',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emasTua,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClaimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.sage.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sageTua.withValues(alpha: 0.4), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: AppColors.sageTua),
                      SizedBox(width: 4),
                      Text(
                        'Sudah Klaim',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          color: AppColors.sageTua,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _isClaimingStreak ? null : _handleClaimStreak,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(70, 36),
                  ),
                  child: _isClaimingStreak
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teksGelap),
                        )
                      : const Text('Klaim', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Day streak dots: Sen Sel Rab Kam Jum Sab Min
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayDot('Sen', 1 <= currentWibWeekday && (1 < currentWibWeekday || isClaimed)),
              _buildDayDot('Sel', 2 <= currentWibWeekday && (2 < currentWibWeekday || isClaimed)),
              _buildDayDot('Rab', 3 <= currentWibWeekday && (3 < currentWibWeekday || isClaimed)),
              _buildDayDot('Kam', 4 <= currentWibWeekday && (4 < currentWibWeekday || isClaimed)),
              _buildDayDot('Jum', 5 <= currentWibWeekday && (5 < currentWibWeekday || isClaimed)),
              _buildDayDot('Sab', 6 <= currentWibWeekday && (6 < currentWibWeekday || isClaimed)),
              _buildDayDot('Min', 7 <= currentWibWeekday && (7 < currentWibWeekday || isClaimed)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayDot(String dayLabel, bool isDone) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone ? AppColors.sageTua : AppColors.gading,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? AppColors.sageTua : AppColors.sage.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(
            isDone ? Icons.check_rounded : Icons.circle_outlined,
            size: 16,
            color: isDone ? AppColors.teksPutih : AppColors.sage,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.teksGelap,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChallengeCard() {
    final challenge = _dailyChallenge;
    final category = challenge?.category ?? 'Biologi';
    final question = challenge?.questionText ?? 'Berapa jumlah kantung tenggorokan pada Bekantan (Nasalis larvatus) jantan dewasa?';
    final options = challenge?.options ?? [
      '1 kantung resonansi besar',
      '2 kantung simetris',
      '3 rongga udara',
      'Tidak memiliki kantung',
    ];
    final alreadyAnswered = challenge?.alreadyAnswered ?? false;
    final isCorrect = challenge?.isCorrect ?? false;
    final selectedOpt = challenge?.selectedOption;
    final correctOpt = challenge?.correctOption;
    final explanation = challenge?.explanation;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.sageTua, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tantangan Hari Ini ($category)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.teksGelap,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gading,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emasTua.withValues(alpha: 0.4), width: 1),
                ),
                child: const Text(
                  '+50 Poin',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emasTua,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.teksGelap,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Pilihan Jawaban
          if (!alreadyAnswered) ...[
            if (_isSubmittingChallenge)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageTua),
                ),
              )
            else
              Column(
                children: List.generate(options.length, (index) {
                  const letters = ['A', 'B', 'C', 'D'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _handleAnswerDailyChallenge(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.gading,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sage.withValues(alpha: 0.45), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.sageTua,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                letters[index],
                                style: const TextStyle(
                                  color: AppColors.teksPutih,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                options[index],
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.teksGelap,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.sage),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: AppColors.teksGelap),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '1 kali kesempatan per hari • Reset 00:00 WIB',
                    style: TextStyle(fontSize: 10.5, color: AppColors.teksGelap),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Status Sudah Dijawab
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isCorrect ? AppColors.sageTua : AppColors.merahStatus,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: AppColors.teksPutih,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCorrect ? 'Jawabanmu Benar! (+50 Poin)' : 'Jawabanmu Kurang Tepat (0 Poin)',
                      style: const TextStyle(
                        color: AppColors.teksPutih,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Ulasan Jawaban
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gading,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedOpt != null && selectedOpt >= 0 && selectedOpt < options.length)
                    Text(
                      'Pilihanmu: ${options[selectedOpt]}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCorrect ? AppColors.sageTua : AppColors.merahStatus,
                      ),
                    ),
                  if (!isCorrect && correctOpt != null && correctOpt >= 0 && correctOpt < options.length) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Kunci Jawaban: ${options[correctOpt]}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sageTua,
                      ),
                    ),
                  ],
                  if (explanation != null && explanation.isNotEmpty) ...[
                    const Divider(height: 16, thickness: 0.8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.emasTua),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            explanation,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.teksGelap,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tantangan baru tersedia besok pukul 00:00 WIB.',
              style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.teksGelap),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizArenaCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Arena Kuis Satwa Liar',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.teksGelap,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sageTua,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Skor Terbaik: ${QuizService.instance.getBestQuizScore() > 0 ? QuizService.instance.getBestQuizScore().toString() : 'Belum Ada'}',
                  style: const TextStyle(
                    color: AppColors.teksPutih,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '10 soal taksonomi • Timer 15 detik • 3 nyawa • Bonus kombo. Skor dihitung dan divalidasi langsung oleh server database.',
            style: TextStyle(fontSize: 12, color: AppColors.teksGelap, height: 1.35),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _isStartingQuiz ? null : _handleStartQuiz,
            icon: _isStartingQuiz
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageTua),
                  )
                : const Icon(Icons.sports_esports_outlined, size: 18),
            label: Text(_isStartingQuiz ? 'Menyiapkan Soal Server...' : 'Mulai Sesi Kuis (10 Soal)'),
          ),
        ],
      ),
    );
  }

  Widget _buildShakeToQuizBanner() {
    final remaining = _shakeQuota?.remainingQuota ?? 3;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sageTua.withValues(alpha: 0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: _isClaimingShake ? null : _handleShakeTriggered,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gading.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: _isClaimingShake
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.sageTua),
                        )
                      : const Icon(Icons.vibration_rounded, color: AppColors.teksGelap, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Goyang HP (Shake-to-Quiz)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.teksGelap,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.gading,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Kuota $remaining/3',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teksGelap,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sensor accelerometer mendeteksi goyangan fisik (atau ketuk banner) untuk memunculkan soal kejutan.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
