// ==============================================================================
// FAUNOVA MODEL: QuizSessionModel & QuizAnswerInput
// Sesuai Plan 5.8 & AGENTS.md (Sesi S13)
// ==============================================================================

import 'quiz_question_model.dart';

class QuizSessionModel {
  final String sessionId;
  final int totalQuestions;
  final List<QuizQuestionModel> questions;

  const QuizSessionModel({
    required this.sessionId,
    required this.totalQuestions,
    required this.questions,
  });

  factory QuizSessionModel.fromJson(Map<String, dynamic> json) {
    final rawQ = json['questions'];
    List<QuizQuestionModel> list = [];
    if (rawQ is List) {
      list = rawQ
          .map((item) => QuizQuestionModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    return QuizSessionModel(
      sessionId: json['session_id']?.toString() ?? '',
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? list.length,
      questions: list,
    );
  }
}

class QuizAnswerInput {
  final String questionId;
  final int? selectedOption; // 0..3, atau null jika waktu habis
  final int elapsedMs;

  const QuizAnswerInput({
    required this.questionId,
    required this.selectedOption,
    required this.elapsedMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'selected_option': selectedOption,
      'elapsed_ms': elapsedMs,
    };
  }
}
