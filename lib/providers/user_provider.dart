import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/models/user_avatar_config.dart';
import '../data/models/home_model.dart';
import 'auth_provider.dart';

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final notifier = UserNotifier(api);
  
  // Listen to auth changes to clear state on logout
  ref.listen(authProvider, (previous, next) {
    if (previous?.isLoggedIn == true && next.isLoggedIn == false) {
      notifier.clear();
    }
  });
  
  return notifier;
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
  int _profileRequestId = 0;
  int _homeRequestId = 0;

  UserNotifier(this._api) : super(const UserState());

  Future<void> loadProfile() async {
    final requestId = ++_profileRequestId;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _api.getUserProfile();
      if (requestId != _profileRequestId) return;
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      if (requestId != _profileRequestId) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadHome() async {
    final requestId = ++_homeRequestId;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final home = await _api.getHome();
      if (requestId != _homeRequestId) return;
      state = state.copyWith(homeData: home, isLoading: false);
    } catch (e) {
      if (requestId != _homeRequestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateAvatar(UserAvatarConfig config, {int? upPoints, Map<String, dynamic>? purchasedItems}) async {
    state = state.copyWith(isLoading: true);
    try {
      final originalName = state.profile?.name ?? 'default';
      final trimmedName = originalName.trim();
      final lowerName = trimmedName.toLowerCase();
      
      final configJson = config.toJson();
      final newAvatarMap = {
        ...(state.profile?.rawAvatarMap ?? {}),
        originalName: configJson,
        trimmedName: configJson,
        lowerName: configJson,
      };

      // Global Sync: Save purchases under all name variations to guarantee web compatibility
      final currentPurchases = purchasedItems?[originalName] ?? 
                               purchasedItems?['default'] ?? 
                               state.profile?.rawPurchasedMap?[originalName] ?? 
                               state.profile?.rawPurchasedMap?['default'] ?? [];
                               
      final newPurchasedMap = {
        ...(state.profile?.rawPurchasedMap ?? {}),
        originalName: currentPurchases,
        trimmedName: currentPurchases,
        lowerName: currentPurchases,
      };
      
      final finalPoints = upPoints ?? state.profile?.upPoints ?? 0;
      
      await _api.updateUser({
        'avatarConfig': newAvatarMap,
        'upPoints': finalPoints,
        'avatar': newAvatarMap,
        'up_points': finalPoints,
        'purchasedAvatarItems': newPurchasedMap,
      });
      
      final updatedProfile = state.profile?.copyWith(
        avatarConfig: config,
        rawAvatarMap: newAvatarMap,
        rawPurchasedMap: newPurchasedMap,
        upPoints: finalPoints,
      );
      
      state = state.copyWith(profile: updatedProfile, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clear() {
    _profileRequestId++;
    _homeRequestId++;
    state = const UserState();
  }
}
