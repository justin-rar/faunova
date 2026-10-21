// ==============================================================================
// FAUNOVA MODEL: QuizQuestionModel
// Model soal kuis biologi satwa liar untuk klien
// Aturan Keras AGENTS.md: Kunci jawaban (correct_option) TIDAK PERNAH dikirim ke klien!
// ==============================================================================

class QuizQuestionModel {
  final String id;
  final String category;
  final String question;
  final List<String> options;

  const QuizQuestionModel({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    }

    return QuizQuestionModel(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Fauna',
      question: json['question']?.toString() ?? '',
      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'options': options,
    };
  }
}
