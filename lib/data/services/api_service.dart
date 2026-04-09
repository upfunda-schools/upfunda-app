import '../models/user_model.dart';
import '../models/home_model.dart';
import '../models/subjects_model.dart';
import '../models/topics_model.dart';
import '../models/quiz_model.dart';
import '../models/submit_model.dart';
import '../models/challenge_model.dart';
import '../models/challenge_room_model.dart';
import '../models/profile_model.dart';

abstract class ApiService {
  Future<UserProfile> getUserProfile();

  Future<List<StudentProfile>> getStudentProfiles();

  // Mobile v1 endpoints
  Future<HomeResponse> getHome();

  Future<SubjectsResponse> getSubjects();

  Future<TopicsResponse> getTopics(String subjectId);

  Future<TestDetailsResponse> getTestDetails(
    String testId, {
    int page = 1,
    int limit = 10,
  });

  Future<AnswerResponse> submitAnswer(
    String testId,
    SubmitAnswerRequest request,
  );

  Future<SubmitTestResponse> submitTest(String testId);

  Future<void> pauseTest(String testId);

  Future<void> resumeTest(String testId);

  // Challenge (bot) endpoints
  Future<BotChallengeSession> startChallenge();

  // Challenge Room (friend) endpoints
  Future<ChallengeRoomCreated> createChallengeRoom({required String classId});

  Future<ChallengeRoomJoined> joinChallengeRoom(String roomCode);

  Future<ChallengeRoomResult> startChallengeRoom(String roomId);

  Future<SingleAnswerResult> submitChallengeRoomAnswer({
    required String roomId,
    required String questionId,
    required String selectedOptionId,
    required int timeTakenSeconds,
  });

  Future<ChallengeRoomResult> getChallengeRoomResult(String roomId);

  Future<void> quitChallengeRoom(String roomId);

}
