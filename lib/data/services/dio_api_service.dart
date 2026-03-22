import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/home_model.dart';
import '../models/subjects_model.dart';
import '../models/topics_model.dart';
import '../models/quiz_model.dart';
import '../models/submit_model.dart';
import 'api_service.dart';
import 'firebase_auth_service.dart';

class DioApiService implements ApiService {
  final Dio _dio;
  final String userId;

  DioApiService({
    required this.userId,
    required String baseUrl,
    required FirebaseAuthService authService,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await authService.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await authService.signOut();
        }
        return handler.next(error);
      },
    ));
  }

  Map<String, dynamic> _userParams([Map<String, dynamic>? extra]) {
    final params = <String, dynamic>{'user_id': userId};
    if (extra != null) params.addAll(extra);
    return params;
  }

  @override
  Future<UserProfile> getUserProfile() async {
    // Profile endpoint uses Bearer token, but for now we'll use home data
    // as a workaround since we don't have Firebase auth set up
    final response = await _dio.get(
      '/mobile/v1/home',
      queryParameters: _userParams(),
    );
    final data = response.data;
    return UserProfile(
      id: data['student_id'] ?? '',
      email: '',
      role: 'student',
      name: data['student_name'] ?? '',
      upPoints: data['up_points'] ?? 0,
      schoolId: data['school_id'] ?? '',
      studentId: data['student_id'] ?? '',
      isPremiumUser: data['is_premium_user'] ?? false,
    );
  }

  @override
  Future<HomeResponse> getHome() async {
    final response = await _dio.get(
      '/mobile/v1/home',
      queryParameters: _userParams(),
    );
    return HomeResponse.fromJson(response.data);
  }

  @override
  Future<SubjectsResponse> getSubjects() async {
    final response = await _dio.get(
      '/mobile/v1/subjects',
      queryParameters: _userParams(),
    );
    return SubjectsResponse.fromJson(response.data);
  }

  @override
  Future<TopicsResponse> getTopics(String subjectId) async {
    final response = await _dio.get(
      '/mobile/v1/subjects/$subjectId/topics',
      queryParameters: _userParams(),
    );
    return TopicsResponse.fromJson(response.data);
  }

  @override
  Future<TestDetailsResponse> getTestDetails(
    String testId, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '/mobile/v1/tests/$testId',
      queryParameters: _userParams({
        'page': page,
        'limit': limit,
      }),
    );
    return TestDetailsResponse.fromJson(response.data);
  }

  @override
  Future<AnswerResponse> submitAnswer(
    String testId,
    SubmitAnswerRequest request,
  ) async {
    final response = await _dio.post(
      '/mobile/v1/tests/$testId/answer',
      queryParameters: _userParams(),
      data: request.toJson(),
    );
    return AnswerResponse.fromJson(response.data);
  }

  @override
  Future<SubmitTestResponse> submitTest(String testId) async {
    final response = await _dio.post(
      '/mobile/v1/tests/$testId/submit',
      queryParameters: _userParams(),
    );
    return SubmitTestResponse.fromJson(response.data);
  }
}
