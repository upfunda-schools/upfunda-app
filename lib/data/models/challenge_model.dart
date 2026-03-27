class ChallengeOption {
  final String optionId;
  final String optionText;
  final String optionLabel;
  final String? image;

  ChallengeOption({
    required this.optionId,
    required this.optionText,
    required this.optionLabel,
    this.image,
  });

  factory ChallengeOption.fromJson(Map<String, dynamic> json) => ChallengeOption(
        optionId: json['option_id'] ?? '',
        optionText: json['option_text'] ?? '',
        optionLabel: json['option_label'] ?? '',
        image: json['image'],
      );
}

class QuestionMetadata {
  final String? subjectId;
  final String? topicId;
  final String difficulty;

  QuestionMetadata({this.subjectId, this.topicId, required this.difficulty});

  factory QuestionMetadata.fromJson(Map<String, dynamic> json) => QuestionMetadata(
        subjectId: json['subject_id'],
        topicId: json['topic_id'],
        difficulty: json['difficulty'] ?? '',
      );
}

class BotBehavior {
  final int timeTakenSeconds;
  final bool willAnswerCorrectly;
  final String selectedOptionId;

  BotBehavior({
    required this.timeTakenSeconds,
    required this.willAnswerCorrectly,
    required this.selectedOptionId,
  });

  factory BotBehavior.fromJson(Map<String, dynamic> json) => BotBehavior(
        timeTakenSeconds: json['time_taken_seconds'] ?? 0,
        willAnswerCorrectly: json['will_answer_correctly'] ?? false,
        selectedOptionId: json['selected_option_id'] ?? '',
      );
}

class BotQuestion {
  final String questionId;
  final int questionNumber;
  final String questionText;
  final String questionType;
  final String? image;
  final List<ChallengeOption> options;
  final String correctOptionId;
  final QuestionMetadata metadata;
  final BotBehavior botBehavior;

  BotQuestion({
    required this.questionId,
    required this.questionNumber,
    required this.questionText,
    required this.questionType,
    this.image,
    required this.options,
    required this.correctOptionId,
    required this.metadata,
    required this.botBehavior,
  });

  factory BotQuestion.fromJson(Map<String, dynamic> json) => BotQuestion(
        questionId: json['question_id'] ?? '',
        questionNumber: json['question_number'] ?? 0,
        questionText: json['question_text'] ?? '',
        questionType: json['question_type'] ?? '',
        image: json['image'],
        options: (json['options'] as List? ?? [])
            .map((o) => ChallengeOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        correctOptionId: json['correct_option_id'] ?? '',
        metadata: QuestionMetadata.fromJson(
            (json['metadata'] as Map<String, dynamic>?) ?? {}),
        botBehavior: BotBehavior.fromJson(
            (json['bot_behavior'] as Map<String, dynamic>?) ?? {}),
      );
}

class BotOpponent {
  final String id;
  final String name;
  final String grade;

  BotOpponent({required this.id, required this.name, required this.grade});

  factory BotOpponent.fromJson(Map<String, dynamic> json) => BotOpponent(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        grade: json['grade'] ?? '',
      );
}

class BotChallengeSession {
  final String sessionId;
  final String studentId;
  final String studentName;
  final BotOpponent opponent;
  final List<BotQuestion> questions;

  BotChallengeSession({
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.opponent,
    required this.questions,
  });

  factory BotChallengeSession.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    final student = (data['student'] as Map<String, dynamic>?) ?? {};
    return BotChallengeSession(
      sessionId: data['session_id'] ?? '',
      studentId: student['id'] ?? '',
      studentName: student['name'] ?? '',
      opponent: BotOpponent.fromJson(
          (data['opponent'] as Map<String, dynamic>?) ?? {}),
      questions: (data['questions'] as List? ?? [])
          .map((q) => BotQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}
