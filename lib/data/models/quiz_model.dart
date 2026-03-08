class TestDetailsResponse {
  final String testId;
  final String testName;
  final int durationSeconds;
  final QuizTimer? timer;
  final List<Question> questions;
  final List<AlreadyAnswered> alreadyAnswered;
  final Pagination pagination;

  TestDetailsResponse({
    required this.testId,
    required this.testName,
    required this.durationSeconds,
    this.timer,
    required this.questions,
    required this.alreadyAnswered,
    required this.pagination,
  });

  factory TestDetailsResponse.fromJson(Map<String, dynamic> json) =>
      TestDetailsResponse(
        testId: json['test_id'] as String? ?? '',
        testName: json['test_name'] as String? ?? '',
        durationSeconds: json['duration_seconds'] as int? ?? 0,
        timer: json['timer'] != null
            ? QuizTimer.fromJson(json['timer'] as Map<String, dynamic>)
            : null,
        questions: (json['questions'] as List<dynamic>)
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
        alreadyAnswered: (json['already_answered'] as List<dynamic>?)
                ?.map(
                    (e) => AlreadyAnswered.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        pagination:
            Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
      );
}

class QuizTimer {
  final int remainingSeconds;
  final bool isPaused;
  final int totalPausedSeconds;

  QuizTimer({
    required this.remainingSeconds,
    required this.isPaused,
    required this.totalPausedSeconds,
  });

  factory QuizTimer.fromJson(Map<String, dynamic> json) => QuizTimer(
        remainingSeconds: json['remaining_seconds'] as int? ?? 0,
        isPaused: json['is_paused'] as bool? ?? false,
        totalPausedSeconds: json['total_paused_seconds'] as int? ?? 0,
      );
}

class Question {
  final String questionId;
  final String text;
  final String type; // MCQ, FILL_UP, TRUE_FALSE, INTEGER
  final List<QuestionOption> options;
  final Solution? solution;

  Question({
    required this.questionId,
    required this.text,
    required this.type,
    required this.options,
    this.solution,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        questionId: json['question_id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        type: json['type'] as String? ?? 'MCQ',
        options: (json['options'] as List<dynamic>?)
                ?.map(
                    (e) => QuestionOption.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        solution: json['solution'] != null
            ? Solution.fromJson(json['solution'] as Map<String, dynamic>)
            : null,
      );

  bool get isFillType => type == 'FILL_UP' || type == 'INTEGER';
}

class QuestionOption {
  final String optionId;
  final String text;

  QuestionOption({required this.optionId, required this.text});

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
        optionId: json['option_id'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );
}

class Solution {
  final String answer;
  final String explanation;
  final String? correctOptionId;

  Solution({
    required this.answer,
    required this.explanation,
    this.correctOptionId,
  });

  factory Solution.fromJson(Map<String, dynamic> json) => Solution(
        answer: json['answer'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        correctOptionId: json['correct_option_id'] as String?,
      );
}

class AlreadyAnswered {
  final String questionId;
  final String selectedOptionId;
  final bool isCorrect;

  AlreadyAnswered({
    required this.questionId,
    required this.selectedOptionId,
    required this.isCorrect,
  });

  factory AlreadyAnswered.fromJson(Map<String, dynamic> json) =>
      AlreadyAnswered(
        questionId: json['question_id'] as String? ?? '',
        selectedOptionId: json['selected_option_id'] as String? ?? '',
        isCorrect: json['is_correct'] as bool? ?? false,
      );
}

class Pagination {
  final int currentPage;
  final int pageSize;
  final int totalQuestions;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  Pagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalQuestions,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        currentPage: json['current_page'] as int? ?? 1,
        pageSize: json['page_size'] as int? ?? 10,
        totalQuestions: json['total_questions'] as int? ?? 0,
        totalPages: json['total_pages'] as int? ?? 1,
        hasNext: json['has_next'] as bool? ?? false,
        hasPrevious: json['has_previous'] as bool? ?? false,
      );
}
