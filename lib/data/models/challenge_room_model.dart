import 'challenge_model.dart';

class ChallengeRoomCreated {
  final String roomId;
  final String roomCode;
  final String status;

  ChallengeRoomCreated({
    required this.roomId,
    required this.roomCode,
    required this.status,
  });

  factory ChallengeRoomCreated.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return ChallengeRoomCreated(
      roomId: data['room_id'] ?? '',
      roomCode: data['room_code'] ?? '',
      status: data['status'] ?? '',
    );
  }
}

class ChallengeRoomJoined {
  final String roomId;
  final String status;

  ChallengeRoomJoined({required this.roomId, required this.status});

  factory ChallengeRoomJoined.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return ChallengeRoomJoined(
      roomId: data['room_id'] ?? '',
      status: data['status'] ?? '',
    );
  }
}

class SingleAnswerResult {
  final bool correct;
  final int answeredCount;
  final int totalQuestions;
  final bool finished;

  SingleAnswerResult({
    required this.correct,
    required this.answeredCount,
    required this.totalQuestions,
    required this.finished,
  });

  factory SingleAnswerResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return SingleAnswerResult(
      correct: data['correct'] ?? false,
      answeredCount: data['answered_count'] ?? 0,
      totalQuestions: data['total_questions'] ?? 0,
      finished: data['finished'] ?? false,
    );
  }
}

class ChallengeRoomWinner {
  final String playerId;
  final String name;
  final int score;
  final double totalTime;

  ChallengeRoomWinner({
    required this.playerId,
    required this.name,
    required this.score,
    required this.totalTime,
  });

  factory ChallengeRoomWinner.fromJson(Map<String, dynamic> json) =>
      ChallengeRoomWinner(
        playerId: json['playerId'] ?? '',
        name: json['name'] ?? '',
        score: json['score'] ?? 0,
        totalTime: (json['totalTime'] ?? 0).toDouble(),
      );
}

class ChallengeRoomPlayer {
  final String playerId;
  final String name;
  final bool isWinner;
  final int score;
  final double totalTime;
  final int correct;
  final int wrong;
  final int answered;
  final bool finished;
  final bool hasQuit;
  final List<bool?> questionResults;

  ChallengeRoomPlayer({
    required this.playerId,
    required this.name,
    required this.isWinner,
    required this.score,
    required this.totalTime,
    required this.correct,
    required this.wrong,
    required this.answered,
    required this.finished,
    required this.hasQuit,
    required this.questionResults,
  });

  factory ChallengeRoomPlayer.fromJson(Map<String, dynamic> json) =>
      ChallengeRoomPlayer(
        playerId: json['playerId'] ?? '',
        name: json['name'] ?? '',
        isWinner: json['isWinner'] ?? false,
        score: json['score'] ?? 0,
        totalTime: (json['totalTime'] ?? 0).toDouble(),
        correct: json['correct'] ?? 0,
        wrong: json['wrong'] ?? 0,
        answered: json['answered'] ?? 0,
        finished: json['finished'] ?? false,
        hasQuit: json['hasQuit'] ?? false,
        questionResults: (json['questionResults'] as List? ?? [])
            .map((r) => r as bool?)
            .toList(),
      );
}

class ChallengeRoomActions {
  final bool rematchAllowed;
  final bool exitAllowed;

  ChallengeRoomActions({
    required this.rematchAllowed,
    required this.exitAllowed,
  });

  factory ChallengeRoomActions.fromJson(Map<String, dynamic> json) =>
      ChallengeRoomActions(
        rematchAllowed: json['rematchAllowed'] ?? false,
        exitAllowed: json['exitAllowed'] ?? true,
      );
}

class RoomChallengeQuestion {
  final String questionId;
  final int questionNumber;
  final String questionText;
  final String questionType;
  final String? image;
  final List<ChallengeOption> options;
  final String correctOptionId;
  final QuestionMetadata metadata;

  RoomChallengeQuestion({
    required this.questionId,
    required this.questionNumber,
    required this.questionText,
    required this.questionType,
    this.image,
    required this.options,
    required this.correctOptionId,
    required this.metadata,
  });

  factory RoomChallengeQuestion.fromJson(Map<String, dynamic> json) =>
      RoomChallengeQuestion(
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
      );
}

class ChallengeRoomResult {
  final String roomId;
  final String status;
  final ChallengeRoomWinner? winner;
  final List<ChallengeRoomPlayer> players;
  final String resultReason;
  final ChallengeRoomActions actions;
  final List<RoomChallengeQuestion> questions;

  ChallengeRoomResult({
    required this.roomId,
    required this.status,
    this.winner,
    required this.players,
    required this.resultReason,
    required this.actions,
    required this.questions,
  });

  factory ChallengeRoomResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return ChallengeRoomResult(
      roomId: data['roomId'] ?? '',
      status: data['status'] ?? '',
      winner: data['winner'] != null
          ? ChallengeRoomWinner.fromJson(
              data['winner'] as Map<String, dynamic>)
          : null,
      players: (data['players'] as List? ?? [])
          .map((p) =>
              ChallengeRoomPlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      resultReason: data['resultReason'] ?? '',
      actions: ChallengeRoomActions.fromJson(
          (data['actions'] as Map<String, dynamic>?) ?? {}),
      questions: (data['questions'] as List? ?? [])
          .map((q) => RoomChallengeQuestion.fromJson(
              q as Map<String, dynamic>))
          .toList(),
    );
  }
}
