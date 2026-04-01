import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/env_config.dart';
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

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? error,
    User? user,
    bool clearUser = false,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        user: clearUser ? null : (user ?? this.user),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;
  StreamSubscription<User?>? _authSub;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSub = _authService.authStateChanges().listen((user) {
      state = state.copyWith(
        isLoggedIn: user != null,
        user: user,
        clearUser: user == null,
      );
    });
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        user: credential.user,
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));
      final res = await dio.post('/auth/phone/login',
          data: {'phone': phone, 'password': password});
      final customToken = res.data['custom_token'] as String;
      final credential = await _authService.signInWithCustomToken(customToken);
      state = state.copyWith(isLoggedIn: true, isLoading: false, user: credential.user);
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

  Future<void> logout() async {
    await _authService.signOut();
    state = const AuthState(isLoggedIn: false);
  }

  Future<bool> phoneRegister({required String phone, required String password}) async {
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
        user: credential.user
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
        user: credential.user
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
