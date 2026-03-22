import '../mock/mock_data.dart';
import '../models/user_model.dart';
import '../models/home_model.dart';
import '../models/subjects_model.dart';
import '../models/topics_model.dart';
import '../models/quiz_model.dart';
import '../models/submit_model.dart';
import 'api_service.dart';

class MockApiService implements ApiService {
  @override
  Future<UserProfile> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockData.userProfile;
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
}
