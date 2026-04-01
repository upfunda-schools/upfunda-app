import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/home_model.dart';
import '../models/subjects_model.dart';
import '../models/topics_model.dart';
import '../models/quiz_model.dart';
import '../models/submit_model.dart';
import '../models/challenge_model.dart';
import '../models/challenge_room_model.dart';
import 'api_service.dart';
import 'firebase_auth_service.dart';

class DioApiService implements ApiService {
  final Dio _dio;

  DioApiService({
    String? userId,
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
        // Temporarily disabled auto-sign-out on 401 to prevent 'snap back' behavior
        // if (error.response?.statusCode == 401) {
        //   await authService.signOut();
        // }
        return handler.next(error);
      },
    ));
  }

  Map<String, dynamic> _userParams([Map<String, dynamic>? extra]) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final params = <String, dynamic>{'user_id': uid};
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
      email: data['email'] ?? '',
      role: 'student',
      name: data['student_name'] ?? '',
      upPoints: data['up_points'] ?? 0,
      schoolId: data['school_id'] ?? '',
      schoolName: data['school_name'],
      className: data['class_name'],
      country: data['country'],
      phone: data['phone'],
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

  @override
  Future<BotChallengeSession> startChallenge() async {
    final response = await _dio.post(
      '/mobile/v1/challenge/start',
      queryParameters: _userParams(),
      data: {},
    );
    return BotChallengeSession.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChallengeRoomCreated> createChallengeRoom() async {
    final response = await _dio.post(
      '/mobile/v1/challenge-room/create',
      queryParameters: _userParams(),
      data: {},
    );
    return ChallengeRoomCreated.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChallengeRoomJoined> joinChallengeRoom(String roomCode) async {
    final response = await _dio.post(
      '/mobile/v1/challenge-room/join',
      queryParameters: _userParams(),
      data: {'room_code': roomCode},
    );
    return ChallengeRoomJoined.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChallengeRoomResult> startChallengeRoom(String roomId) async {
    final response = await _dio.post(
      '/mobile/v1/challenge-room/start',
      queryParameters: _userParams(),
      data: {'room_id': roomId},
    );
    return ChallengeRoomResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SingleAnswerResult> submitChallengeRoomAnswer({
    required String roomId,
    required String questionId,
    required String selectedOptionId,
    required int timeTakenSeconds,
  }) async {
    final response = await _dio.post(
      '/mobile/v1/challenge-room/submit-answer',
      queryParameters: _userParams(),
      data: {
        'room_id': roomId,
        'question_id': questionId,
        'selected_option_id': selectedOptionId,
        'time_taken_seconds': timeTakenSeconds,
      },
    );
    return SingleAnswerResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChallengeRoomResult> getChallengeRoomResult(String roomId) async {
    final response = await _dio.post(
      '/mobile/v1/challenge-room/result',
      queryParameters: _userParams(),
      data: {'room_id': roomId},
    );
    return ChallengeRoomResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> quitChallengeRoom(String roomId) async {
    await _dio.post(
      '/mobile/v1/challenge-room/quit',
      queryParameters: _userParams(),
      data: {'room_id': roomId},
    );
  }
}
