// ==============================================================================
// FAUNOVA WIDGET: ShakeQuizSheet
// Lembar interaktif Kuis Goyang HP (Shake-to-Quiz)
// Sesuai Plan 5.8 (190-196) & AGENTS.md Desain Visual
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../core/services/shake_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/shake_quiz_model.dart';

class ShakeQuizSheet extends StatefulWidget {
  final ShakeQuizClaimModel claim;
  final VoidCallback onQuizFinished;

  const ShakeQuizSheet({
    super.key,
    required this.claim,
    required this.onQuizFinished,
  });

  static Future<void> show(
    BuildContext context, {
    required ShakeQuizClaimModel claim,
    required VoidCallback onQuizFinished,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShakeQuizSheet(
        claim: claim,
        onQuizFinished: onQuizFinished,
      ),
    );
  }

  @override
  State<ShakeQuizSheet> createState() => _ShakeQuizSheetState();
}

class _ShakeQuizSheetState extends State<ShakeQuizSheet> {
  bool _isSubmitting = false;
  ShakeQuizResultModel? _result;

  Future<void> _handleAnswer(int optionIndex) async {
    if (_isSubmitting || _result != null) return;
    setState(() => _isSubmitting = true);

    try {
      final res = await ShakeService.instance.answerShakeQuiz(
        claimId: widget.claim.claimId,
        selectedOption: optionIndex,
      );

      if (mounted) {
        setState(() {
          _result = res;
          _isSubmitting = false;
        });
        widget.onQuizFinished();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim jawaban: $e'),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final claim = widget.claim;
    final options = claim.options;
    const letters = ['A', 'B', 'C', 'D'];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.sage.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.sageTua,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vibration_rounded,
                  color: AppColors.teksPutih,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soal Kejutan (${claim.category})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    Text(
                      'Sisa kuota hari ini: ${claim.remainingQuota}/3',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.emasTua,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.teksGelap, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Teks Soal
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sageMuda,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sage.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              claim.questionText,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.teksGelap,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Belum dijawab: 4 Pilihan
          if (_result == null) ...[
            if (_isSubmitting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageTua),
                ),
              )
            else
              ...List.generate(options.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _handleAnswer(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sage.withValues(alpha: 0.5), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
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
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              options[index],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.teksGelap,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.sage),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ] else ...[
            // Sudah dijawab: Tampilkan Hasil dan Pembahasan
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _result!.isCorrect ? AppColors.sageTua : AppColors.merahStatus,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _result!.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: AppColors.teksPutih,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _result!.isCorrect
                          ? 'Jawabanmu Benar! 🎉 (Progres Lencana Si Goyang +1)'
                          : 'Jawabanmu Kurang Tepat',
                      style: const TextStyle(
                        color: AppColors.teksPutih,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sageMuda,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilihanmu: ${options[_result!.selectedOption]}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _result!.isCorrect ? AppColors.sageTua : AppColors.merahStatus,
                    ),
                  ),
                  if (!_result!.isCorrect) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Kunci Jawaban: ${options[_result!.correctOption]}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sageTua,
                      ),
                    ),
                  ],
                  if (_result!.explanation.isNotEmpty) ...[
                    const Divider(height: 16, thickness: 0.8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.emasTua),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _result!.explanation,
                            style: const TextStyle(
                              fontSize: 12,
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
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Selesai & Lanjutkan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
