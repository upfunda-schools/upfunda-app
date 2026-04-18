import '../mock/mock_data.dart';
import '../models/user_model.dart';
import '../models/home_model.dart';
import '../models/subjects_model.dart';
import '../models/topics_model.dart';
import '../models/quiz_model.dart';
import '../models/submit_model.dart';
import '../models/challenge_model.dart';
import '../models/challenge_room_model.dart';
import '../models/profile_model.dart';
import 'api_service.dart';

class MockApiService implements ApiService {
  @override
  Future<UserProfile> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockData.userProfile;
  }

  @override
  Future<List<StudentProfile>> getStudentProfiles() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return []; // Return empty for mock for now
  }

  @override
  Future<HomeResponse> getHome() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return MockData.homeResponse;
  }

  @override
  Future<SubjectsResponse> getSubjects() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.subjectsResponse;
  }

  @override
  Future<TopicsResponse> getTopics(String subjectId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.topicsResponse;
  }

  @override
  Future<TestDetailsResponse> getTestDetails(
    String testId, {
    int page = 1,
    int limit = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return MockData.testDetailsResponse;
  }

  @override
  Future<AnswerResponse> submitAnswer(
    String testId,
    SubmitAnswerRequest request,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.answerResponse;
  }

  @override
  Future<SubmitTestResponse> submitTest(String testId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.submitTestResponse;
  }

  @override
  Future<void> pauseTest(String testId) async {}

  @override
  Future<void> resumeTest(String testId) async {}

  @override
  Future<void> sendHeartbeat(String testId) async {}

  @override
  Future<BotChallengeSession> startChallenge() =>
      throw UnimplementedError('MockApiService does not support challenge');

  @override
  Future<ChallengeRoomCreated> createChallengeRoom({required String classId}) =>
      throw UnimplementedError('MockApiService does not support challenge rooms');

  @override
  Future<ChallengeRoomJoined> joinChallengeRoom(String roomCode) =>
      throw UnimplementedError('MockApiService does not support challenge rooms');

  @override
  Future<ChallengeRoomResult> startChallengeRoom(String roomId) =>
      throw UnimplementedError('MockApiService does not support challenge rooms');

  @override
  Future<SingleAnswerResult> submitChallengeRoomAnswer({
    required String roomId,
    required String questionId,
    required String selectedOptionId,
    required int timeTakenSeconds,
  }) =>
      throw UnimplementedError('MockApiService does not support challenge rooms');

  @override
  Future<ChallengeRoomResult> getChallengeRoomResult(String roomId) =>
      throw UnimplementedError('MockApiService does not support challenge rooms');

  @override
  Future<void> quitChallengeRoom(String roomId) async {
    throw UnimplementedError('MockApiService does not support challenge rooms');
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderBoard({
    required String type,
    required String schoolId,
    required String classId,
    required String sectionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.submitTestResponse.leaderboard;
  }

  @override
  Future<List<LeaderboardEntry>> getClassLeaderBoard({
    required String type,
    required String schoolId,
    required String classId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.submitTestResponse.leaderboard;
  }

  @override
  Future<List<dynamic>> getClasses() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {'id': '1', 'grade': '1', 'name': 'First Grade'},
      {'id': '2', 'grade': '2', 'name': 'Second Grade'},
      {'id': '3', 'grade': '3', 'name': 'Third Grade'},
      {'id': '4', 'grade': '4', 'name': 'Fourth Grade'},
      {'id': '5', 'grade': '5', 'name': 'Fifth Grade'},
    ];
  }

  @override
  Future<List<dynamic>> getSections(String schoolId, String classId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {'id': 's1', 'name': 'A'},
      {'id': 's2', 'name': 'B'},
      {'id': 's3', 'name': 'C'},
    ];
  }

  @override
  Future<void> studentSignUp(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }
}
