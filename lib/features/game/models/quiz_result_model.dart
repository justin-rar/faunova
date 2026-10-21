// ==============================================================================
// FAUNOVA MODEL: QuizResultModel & QuizAnswerSummaryItem
// Hasil kuis yang dihitung dan divalidasi oleh server
// Sesuai Plan 5.8 & AGENTS.md (Sesi S13)
// ==============================================================================

class QuizAnswerSummaryItem {
  final String questionId;
  final String question;
  final int? selectedOption;
  final int correctOption;
  final bool isCorrect;
  final String explanation;

  const QuizAnswerSummaryItem({
    required this.questionId,
    required this.question,
    required this.selectedOption,
    required this.correctOption,
    required this.isCorrect,
    required this.explanation,
  });

  factory QuizAnswerSummaryItem.fromJson(Map<String, dynamic> json) {
    return QuizAnswerSummaryItem(
      questionId: json['question_id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      selectedOption: (json['selected_option'] as num?)?.toInt(),
      correctOption: (json['correct_option'] as num?)?.toInt() ?? 0,
      isCorrect: json['is_correct'] as bool? ?? false,
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

class QuizResultModel {
  final String sessionId;
  final int score;
  final int correctCount;
  final int maxCombo;
  final int previousBest;
  final int bestQuizScore;
  final bool isNewBest;
  final List<QuizAnswerSummaryItem> answersSummary;

  const QuizResultModel({
    required this.sessionId,
    required this.score,
    required this.correctCount,
    required this.maxCombo,
    required this.previousBest,
    required this.bestQuizScore,
    required this.isNewBest,
    required this.answersSummary,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['answers_summary'];
    List<QuizAnswerSummaryItem> list = [];
    if (rawSummary is List) {
      list = rawSummary
          .map((item) => QuizAnswerSummaryItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    return QuizResultModel(
      sessionId: json['session_id']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      maxCombo: (json['max_combo'] as num?)?.toInt() ?? 0,
      previousBest: (json['previous_best'] as num?)?.toInt() ?? 0,
      bestQuizScore: (json['best_quiz_score'] as num?)?.toInt() ?? 0,
      isNewBest: json['is_new_best'] as bool? ?? false,
      answersSummary: list,
    );
  }
}
