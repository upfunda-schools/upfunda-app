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
import '../models/profile_model.dart';
import '../../core/utils/profile_storage.dart';
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
        final profileId = ProfileStorage.profileId;
        if (profileId != null) {
          options.headers['X-Profile-ID'] = profileId;
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
    final response = await _dio.get('/user/profile');
    final data = response.data as Map<String, dynamic>;
    return UserProfile(
      id: data['user_id'] ?? data['id'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      name: data['name'] ?? data['student_name'] ?? '',
      upPoints: data['up_points'] ?? 0,
      schoolId: data['school_id'] ?? '',
      classId: data['class_id'] ?? '',
      schoolName: data['school_name'],
      className: data['class_name'],
      sectionName: data['section_name'],
      sectionId: data['section_id'],
      gender: data['gender'],
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
  Future<List<StudentProfile>> getStudentProfiles() async {
    final response = await _dio.get('/student/profiles');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => StudentProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> pauseTest(String testId) async {
    await _dio.post('/student/test/$testId/pause');
  }

  @override
  Future<void> resumeTest(String testId) async {
    await _dio.post('/student/test/$testId/resume');
  }

  @override
  Future<void> sendHeartbeat(String testId) async {
    await _dio.post('/student/test/$testId/heartbeat');
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
  Future<ChallengeRoomCreated> createChallengeRoom({required String classId}) async {
    final response = await _dio.post(
      '/student/challenge-room/create',
      data: {'class_id': classId},
    );
    return ChallengeRoomCreated.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChallengeRoomJoined> joinChallengeRoom(String roomCode) async {
    final response = await _dio.post(
      '/student/challenge-room/join',
      data: {'room_code': roomCode},
    );
    return ChallengeRoomJoined.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChallengeRoomResult> startChallengeRoom(String roomId) async {
    final response = await _dio.post(
      '/student/challenge-room/start',
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
      '/student/challenge-room/submit-answer',
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
      '/student/challenge-room/result',
      data: {'room_id': roomId},
    );
    return ChallengeRoomResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> quitChallengeRoom(String roomId) async {
    await _dio.post(
      '/student/challenge-room/quit',
      data: {'room_id': roomId},
    );
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderBoard({
    required String type,
    required String schoolId,
    required String classId,
    required String sectionId,
  }) async {
    final response = await _dio.get(
      '/leaderboard/$type/$schoolId/class/$classId/section/$sectionId',
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LeaderboardEntry>> getClassLeaderBoard({
    required String type,
    required String schoolId,
    required String classId,
  }) async {
    final response = await _dio.get(
      '/leaderboard/$type/$schoolId/class/$classId',
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<dynamic>> getClasses() async {
    final response = await _dio.get('/student/class');
    return response.data as List<dynamic>? ?? [];
  }

  @override
  Future<List<dynamic>> getSections(String schoolId, String classId) async {
    final response = await _dio.get('/admin/$schoolId/class/$classId');
    return response.data as List<dynamic>? ?? [];
  }

  @override
  Future<void> studentSignUp(Map<String, dynamic> data) async {
    await _dio.post('/student/signup', data: data);
  }
}
