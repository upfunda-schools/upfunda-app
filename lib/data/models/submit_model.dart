class SubmitAnswerRequest {
  final String questionId;
  final String type;
  final String selectedOptionId;
  final bool isCorrect;
  final int timeTakenSeconds;
  final bool usedFiftyFifty;

  SubmitAnswerRequest({
    required this.questionId,
    required this.type,
    required this.selectedOptionId,
    required this.isCorrect,
    required this.timeTakenSeconds,
    required this.usedFiftyFifty,
  });

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'type': type,
        'selected_option_id': selectedOptionId,
        'is_correct': isCorrect,
        'time_taken_seconds': timeTakenSeconds,
        'used_fifty_fifty': usedFiftyFifty,
      };
}

class AnswerResponse {
  final String status; // submitted, updated

  AnswerResponse({required this.status});

  factory AnswerResponse.fromJson(Map<String, dynamic> json) =>
      AnswerResponse(status: json['status'] as String? ?? 'submitted');
}

class SubmitTestResponse {
  final int correctCount;
  final int totalCount;
  final double score;
  final List<LeaderboardEntry> leaderboard;

  SubmitTestResponse({
    required this.correctCount,
    required this.totalCount,
    required this.score,
    required this.leaderboard,
  });

  factory SubmitTestResponse.fromJson(Map<String, dynamic> json) =>
      SubmitTestResponse(
        correctCount: json['correct_count'] as int? ?? 0,
        totalCount: json['total_count'] as int? ?? 0,
        score: (json['score'] as num?)?.toDouble() ?? 0,
        leaderboard: (json['leaderboard'] as List<dynamic>?)
                ?.map((e) =>
                    LeaderboardEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class LeaderboardEntry {
  final int rank;
  final String studentName;
  final String studentId;
  final double score;

  LeaderboardEntry({
    required this.rank,
    required this.studentName,
    required this.studentId,
    required this.score,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: json['rank'] as int? ?? 0,
        studentName: json['student_name'] as String? ?? '',
        studentId: json['student_id'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
      );
}
