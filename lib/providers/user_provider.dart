import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/models/home_model.dart';
import 'auth_provider.dart';

final userProvider =
    StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.watch(apiServiceProvider));
});

class UserState {
  final UserProfile? profile;
  final HomeResponse? homeData;
  final bool isLoading;
  final String? error;

  const UserState({
    this.profile,
    this.homeData,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    UserProfile? profile,
    HomeResponse? homeData,
    bool? isLoading,
    String? error,
  }) =>
      UserState(
        profile: profile ?? this.profile,
        homeData: homeData ?? this.homeData,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class UserNotifier extends StateNotifier<UserState> {
  final dynamic _api;

  UserNotifier(this._api) : super(const UserState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _api.getUserProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final home = await _api.getHome();
      state = state.copyWith(homeData: home, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const UserState();
  }
}
