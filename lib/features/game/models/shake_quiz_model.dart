// ==============================================================================
// FAUNOVA MODEL: ShakeQuizModel
// Model klaim, kuota, dan jawaban kuis goyang HP (Plan 190-196, 440)
// ==============================================================================

class ShakeQuotaModel {
  final int usedQuota;
  final int maxQuota;
  final int remainingQuota;
  final String dateWib;

  const ShakeQuotaModel({
    required this.usedQuota,
    required this.maxQuota,
    required this.remainingQuota,
    required this.dateWib,
  });

  factory ShakeQuotaModel.fromJson(Map<String, dynamic> json) {
    return ShakeQuotaModel(
      usedQuota: (json['used_quota'] as num?)?.toInt() ?? 0,
      maxQuota: (json['max_quota'] as num?)?.toInt() ?? 3,
      remainingQuota: (json['remaining_quota'] as num?)?.toInt() ?? 3,
      dateWib: json['date_wib'] as String? ?? '',
    );
  }
}

class ShakeQuizClaimModel {
  final String claimId;
  final String questionId;
  final String category;
  final String questionText;
  final List<String> options;
  final int remainingQuota;
  final bool alreadyAnswered;
  final bool quotaExceeded;
  final String message;

  const ShakeQuizClaimModel({
    required this.claimId,
    required this.questionId,
    required this.category,
    required this.questionText,
    required this.options,
    required this.remainingQuota,
    required this.alreadyAnswered,
    this.quotaExceeded = false,
    this.message = '',
  });

  factory ShakeQuizClaimModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    }

    return ShakeQuizClaimModel(
      claimId: json['claim_id'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      category: json['category'] as String? ?? 'Fauna',
      questionText: json['question'] as String? ?? '',
      options: parsedOptions,
      remainingQuota: (json['remaining_quota'] as num?)?.toInt() ?? 0,
      alreadyAnswered: json['already_answered'] as bool? ?? false,
      quotaExceeded: json['quota_exceeded'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}

class ShakeQuizResultModel {
  final String claimId;
  final String questionId;
  final int selectedOption;
  final bool isCorrect;
  final int correctOption;
  final String explanation;
  final String message;

  const ShakeQuizResultModel({
    required this.claimId,
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.correctOption,
    required this.explanation,
    required this.message,
  });

  factory ShakeQuizResultModel.fromJson(Map<String, dynamic> json) {
    return ShakeQuizResultModel(
      claimId: json['claim_id'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      selectedOption: (json['selected_option'] as num?)?.toInt() ?? 0,
      isCorrect: json['is_correct'] as bool? ?? false,
      correctOption: (json['correct_option'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}
