// ==============================================================================
// FAUNOVA MODEL: DailyChallengeModel
// Model Tantangan Hari Ini (Plan 197-200 & Hard Rule 5)
// ==============================================================================

class DailyChallengeModel {
  final String challengeDate;
  final String questionId;
  final String category;
  final String questionText;
  final List<String> options;
  final bool alreadyAnswered;
  final int? selectedOption;
  final bool? isCorrect;
  final int? correctOption;
  final String? explanation;
  final int pointsEarned;
  final String message;

  const DailyChallengeModel({
    required this.challengeDate,
    required this.questionId,
    required this.category,
    required this.questionText,
    required this.options,
    required this.alreadyAnswered,
    this.selectedOption,
    this.isCorrect,
    this.correctOption,
    this.explanation,
    this.pointsEarned = 0,
    this.message = '',
  });

  factory DailyChallengeModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    }

    return DailyChallengeModel(
      challengeDate: json['challenge_date'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      category: json['category'] as String? ?? 'Biologi',
      questionText: json['question'] as String? ?? '',
      options: parsedOptions,
      alreadyAnswered: json['already_answered'] as bool? ?? false,
      selectedOption: (json['selected_option'] as num?)?.toInt(),
      isCorrect: json['is_correct'] as bool?,
      // Aturan Keras 5: correct_option hanya ada jika already_answered == true
      correctOption: (json['correct_option'] as num?)?.toInt(),
      explanation: json['explanation'] as String?,
      pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challenge_date': challengeDate,
      'question_id': questionId,
      'category': category,
      'question': questionText,
      'options': options,
      'already_answered': alreadyAnswered,
      'selected_option': selectedOption,
      'is_correct': isCorrect,
      'correct_option': correctOption,
      'explanation': explanation,
      'points_earned': pointsEarned,
      'message': message,
    };
  }
}
