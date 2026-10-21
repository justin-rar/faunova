// ==============================================================================
// FAUNOVA PRESENTATION: QuizArenaPage
// Layanan arena kuis interaktif 10 soal, timer 15 detik, 3 nyawa, combo, dan validasi server
// Sesuai Dokumen Desain Plan 46, 180-186, 277 & AGENTS.md (Sesi S13)
// ==============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../models/quiz_result_model.dart';
import '../models/quiz_session_model.dart';

class QuizArenaPage extends StatefulWidget {
  final QuizSessionModel session;

  const QuizArenaPage({super.key, required this.session});

  @override
  State<QuizArenaPage> createState() => _QuizArenaPageState();
}

class _QuizArenaPageState extends State<QuizArenaPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _lives = 3;
  int _combo = 0;
  int _maxCombo = 0;
  int _accumulatedScore = 0;

  int? _selectedOption;
  bool _isAnswerLocked = false;
  bool _isSubmitting = false;
  QuizResultModel? _finalResult;

  // Timer 15 detik per soal
  static const int _questionDurationSeconds = 15;
  int _remainingMs = _questionDurationSeconds * 1000;
  Timer? _countdownTimer;
  late Stopwatch _questionStopwatch;

  final List<QuizAnswerInput> _collectedAnswers = [];

  @override
  void initState() {
    super.initState();
    _questionStopwatch = Stopwatch();
    _startQuestionTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _questionStopwatch.stop();
    super.dispose();
  }

  void _startQuestionTimer() {
    _countdownTimer?.cancel();
    _remainingMs = _questionDurationSeconds * 1000;
    _selectedOption = null;
    _isAnswerLocked = false;
    _questionStopwatch.reset();
    _questionStopwatch.start();

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingMs -= 100;
        if (_remainingMs <= 0) {
          _remainingMs = 0;
          timer.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    if (_isAnswerLocked) return;
    _isAnswerLocked = true;
    _questionStopwatch.stop();

    final currentQ = widget.session.questions[_currentIndex];
    _collectedAnswers.add(
      QuizAnswerInput(
        questionId: currentQ.id,
        selectedOption: null, // null menandakan waktu habis
        elapsedMs: _questionDurationSeconds * 1000,
      ),
    );

    // Kehilangan 1 nyawa karena kehabisan waktu
    setState(() {
      _lives--;
      _combo = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Waktu 15 detik habis! Anda kehilangan 1 nyawa.'),
        backgroundColor: AppColors.merahStatus,
        duration: Duration(milliseconds: 1200),
      ),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_lives <= 0) {
        _finishQuiz();
      } else {
        _advanceToNextQuestion();
      }
    });
  }

  void _onSelectOption(int index) {
    if (_isAnswerLocked) return;
    _isAnswerLocked = true;
    _countdownTimer?.cancel();
    _questionStopwatch.stop();

    final elapsed = _questionStopwatch.elapsedMilliseconds;
    final currentQ = widget.session.questions[_currentIndex];

    setState(() {
      _selectedOption = index;
    });

    _collectedAnswers.add(
      QuizAnswerInput(
        questionId: currentQ.id,
        selectedOption: index,
        elapsedMs: elapsed,
      ),
    );

    // Simulasi combo untuk umpan balik visual instan
    setState(() {
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      _accumulatedScore += 100 + (_combo * 25);
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _advanceToNextQuestion();
    });
  }

  void _advanceToNextQuestion() {
    if (_currentIndex + 1 < widget.session.questions.length && _lives > 0) {
      setState(() {
        _currentIndex++;
      });
      _startQuestionTimer();
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    _countdownTimer?.cancel();
    _questionStopwatch.stop();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await QuizService.instance.finishQuizSession(
        sessionId: widget.session.sessionId,
        answers: _collectedAnswers,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _finalResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Galat memvalidasi skor: $e'),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 10;

    return Scaffold(
      backgroundColor: AppColors.gading,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => _confirmExitDialog(),
        ),
        centerTitle: true,
        title: Text(
          _finalResult != null
              ? 'Hasil Arena Kuis'
              : 'Soal ${_currentIndex + 1} dari ${widget.session.questions.length}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16.5,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: _isSubmitting
          ? _buildSubmittingView(topPadding)
          : _finalResult != null
              ? _buildResultView(topPadding)
              : _buildGameplayView(topPadding),
    );
  }

  Widget _buildSubmittingView(double topPadding) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, topPadding, 24, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: AppColors.sageTua,
                strokeWidth: 3.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Menghitung Skor di Server Database...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.teksGelap,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aturan Keras AGENTS.md: Jawaban divalidasi dan dikalkulasi secara deterministik oleh server Postgres.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.teksGelap.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameplayView(double topPadding) {
    final currentQ = widget.session.questions[_currentIndex];
    final timerProgress = _remainingMs / (_questionDurationSeconds * 1000);
    final remainingSeconds = (_remainingMs / 1000).ceil();
    final isCriticalTime = remainingSeconds <= 4;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 40),
      children: [
        // 1. Status Bar Taktis (Nyawa, Timer, Combo)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.sageTua.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 3 Nyawa
              Row(
                children: List.generate(3, (index) {
                  final isAlive = index < _lives;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      isAlive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isAlive ? AppColors.merahStatus : AppColors.sage.withValues(alpha: 0.5),
                      size: 22,
                    ),
                  );
                }),
              ),

              // Combo Streak
              if (_combo > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.emas,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.teksGelap),
                      const SizedBox(width: 4),
                      Text(
                        'Combo x$_combo',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ],
                  ),
                ),

              // Skor Berjalan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sageMuda.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_accumulatedScore Poin',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teksGelap,
                  ),
                ),
              ),

              // Timer Digital
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isCriticalTime ? AppColors.merahStatus : AppColors.sageTua,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${remainingSeconds}s',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: isCriticalTime ? AppColors.merahStatus : AppColors.teksGelap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Visual Progress Bar Timer
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: timerProgress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.sageMuda.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation<Color>(
              isCriticalTime ? AppColors.merahStatus : AppColors.sageTua,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Kartu Soal Kuis
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.sage.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.sageTua.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sageMuda,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentQ.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.teksGelap,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                currentQ.question,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Empat Opsi Pilihan Jawaban (A, B, C, D)
        ...List.generate(currentQ.options.length, (index) {
          const labels = ['A', 'B', 'C', 'D'];
          final optionText = currentQ.options[index];
          final isSelected = _selectedOption == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: _isAnswerLocked ? null : () => _onSelectOption(index),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.emas : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.emasTua
                        : AppColors.sage.withValues(alpha: 0.35),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sageTua.withValues(alpha: isSelected ? 0.12 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.teksGelap : AppColors.sageMuda,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : AppColors.teksGelap,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionText,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.teksGelap,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResultView(double topPadding) {
    final res = _finalResult!;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 40),
      children: [
        // Kartu Utama Skor Server
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.sageTua,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.sageTua.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (res.isNewBest)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emas,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_rounded, size: 16, color: AppColors.teksGelap),
                      SizedBox(width: 6),
                      Text(
                        'REKOR BARU TERCAPAI!',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ],
                  ),
                ),
              const Text(
                'Skor Terverifikasi Server',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${res.score}',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),

              // 3 Metrik Hasil
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultStat('Benar', '${res.correctCount}/${widget.session.questions.length}'),
                  _buildResultStat('Max Combo', 'x${res.maxCombo}'),
                  _buildResultStat('Skor Tertinggi', '${res.bestQuizScore}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Review Jawaban & Edukasi
        const Text(
          'Pembahasan & Kunci Edukasi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.teksGelap,
          ),
        ),
        const SizedBox(height: 10),

        ...List.generate(res.answersSummary.length, (idx) {
          final item = res.answersSummary[idx];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isCorrect
                    ? AppColors.sageTua.withValues(alpha: 0.4)
                    : AppColors.merahStatus.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: item.isCorrect ? AppColors.sageTua : AppColors.merahStatus,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '#${idx + 1} ${item.question}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gading,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.explanation.isNotEmpty ? item.explanation : 'Jawaban benar telah divalidasi server.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.teksGelap.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 14),

        // Tombol Kembali
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(res),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emas,
              foregroundColor: AppColors.teksGelap,
            ),
            child: const Text(
              'Selesai & Kembali ke Arena',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  void _confirmExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.gading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Kuis?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text(
          'Progres sesi kuis yang belum diselesaikan tidak akan tercatat di skor rekor server.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Lanjutkan', style: TextStyle(color: AppColors.sageTua, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merahStatus,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
