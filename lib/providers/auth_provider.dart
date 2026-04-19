import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/env_config.dart';
import '../core/utils/profile_storage.dart';
import '../data/services/api_service.dart';
import '../data/services/dio_api_service.dart';
import '../data/services/firebase_auth_service.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return DioApiService(
    baseUrl: EnvConfig.apiBaseUrl,
    authService: authService,
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(firebaseAuthServiceProvider));
});

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? error;
  final User? user;
  // null = not yet checked, 0 = new user, 1 = single profile, 2+ = multi-profile
  final int? profileCount;
  // True only for login flows that require the student to pick a profile.
  final bool requiresProfileSelection;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.profileCount,
    this.requiresProfileSelection = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? error,
    User? user,
    bool clearUser = false,
    int? profileCount,
    bool clearProfileCount = false,
    bool? requiresProfileSelection,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        user: clearUser ? null : (user ?? this.user),
        profileCount:
            clearProfileCount ? null : (profileCount ?? this.profileCount),
        requiresProfileSelection:
            requiresProfileSelection ?? this.requiresProfileSelection,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;
  StreamSubscription<User?>? _authSub;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSub = _authService.authStateChanges().listen((user) async {
      if (user != null) {
        if (!state.isLoading && ProfileStorage.profileId == null) {
          // App startup with cached Firebase session and no active login() in
          // progress. Fetch profile count before routing so multi-profile users
          // are directed to select_profile_screen instead of student-home.
          state = state.copyWith(isLoggedIn: true, user: user, isLoading: true);
          final idToken = await user.getIdToken();
          final count = await _fetchProfileCount(idToken);
          state = state.copyWith(
            isLoading: false,
            profileCount: count,
            requiresProfileSelection:
                ProfileStorage.profileId == null && (count == null || count != 1),
          );
        } else {
          // During login()/phoneLogin() — let those methods handle profile check.
          state = state.copyWith(isLoggedIn: true, user: user);
        }
      } else {
        state = state.copyWith(isLoggedIn: false, clearUser: true);
      }
    });
  }

  Future<bool> login({required String email, required String password}) async {
    ProfileStorage.profileId = null;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final idToken = await credential.user?.getIdToken();
      final profileCount = await _fetchProfileCount(idToken);
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        user: credential.user,
        profileCount: profileCount,
        requiresProfileSelection:
            ProfileStorage.profileId == null && (profileCount == null || profileCount != 1),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapFirebaseError(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> phoneLogin({required String phone, required String password}) async {
    ProfileStorage.profileId = null;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));
      final res = await dio.post('/auth/phone/login',
          data: {'phone': phone, 'password': password});
      final customToken = res.data['custom_token'] as String;
      final credential = await _authService.signInWithCustomToken(customToken);
      final idToken = await credential.user?.getIdToken();
      final profileCount = await _fetchProfileCount(idToken);
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        user: credential.user,
        profileCount: profileCount,
        requiresProfileSelection:
            ProfileStorage.profileId == null && (profileCount == null || profileCount != 1),
      );
      return true;
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] ?? 'Invalid phone or password';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  /// Fetches /student/profiles and sets ProfileStorage.profileId if exactly 1 profile.
  /// Returns the number of profiles (0, 1, or more). Returns null on error (treat as unknown).
  Future<int?> _fetchProfileCount(String? idToken) async {
    if (idToken == null) return null;
    try {
      final dio = Dio(BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        headers: {'Authorization': 'Bearer $idToken'},
      ));
      final res = await dio.get('/student/profiles');
      final list = (res.data as List<dynamic>?) ?? [];
      if (list.length == 1) {
        final profileId = list[0]['profile_id'] as String?;
        if (profileId != null) ProfileStorage.profileId = profileId;
      } else {
        ProfileStorage.profileId = null;
      }
      return list.length;
    } catch (_) {
      ProfileStorage.profileId = null;
      return null;
    }
  }

  void completeProfileSelection() {
    state = state.copyWith(requiresProfileSelection: false);
  }

  Future<void> logout() async {
    ProfileStorage.profileId = null;
    await _authService.signOut();
    state = const AuthState(
      isLoggedIn: false,
      profileCount: null,
      requiresProfileSelection: false,
    );
  }

  Future<bool> phoneRegister({required String phone, required String password}) async {
    ProfileStorage.profileId = null;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));
      final res = await dio.post('/student/phone/register',
          data: {'phone': phone, 'password': password});
      
      final customToken = res.data['custom_token'] as String;
      final credential = await _authService.signInWithCustomToken(customToken);
      
      state = state.copyWith(
        isLoggedIn: true, 
        isLoading: false, 
        user: credential.user,
        requiresProfileSelection: true,
      );
      return true;
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] ?? 'Sign up failed. Please try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> emailRegister({required String email, required String password}) async {
    ProfileStorage.profileId = null;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));
      final res = await dio.post('/student/email/register',
          data: {'email': email, 'password': password});
      
      final customToken = res.data['custom_token'] as String;
      final credential = await _authService.signInWithCustomToken(customToken);
      
      state = state.copyWith(
        isLoggedIn: true, 
        isLoading: false, 
        user: credential.user,
        requiresProfileSelection: true,
      );
      return true;
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] ?? 'Sign up failed. Please try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> resetPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapFirebaseError(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      default:
        return 'Sign in failed. Please try again';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
