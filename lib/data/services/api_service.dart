import '../models/user_model.dart';
import '../models/home_model.dart';
import '../models/subjects_model.dart';
import '../models/topics_model.dart';
import '../models/quiz_model.dart';
import '../models/submit_model.dart';

abstract class ApiService {
  // Auth
  Future<LoginResponse> loginWithPhone({
    required String phone,
    required String password,
  });

  Future<UserProfile> getUserProfile();

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
}
