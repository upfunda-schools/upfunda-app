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
    final originalState = state;
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
    
    // 1. Optimistic Update
    final name = state.profile?.name ?? 'default';
    final searchName = name.trim().toLowerCase();
    
    List<PurchasedAvatar>? newPurchasedList;
    if (purchasedItems != null) {
      var rawList = purchasedItems[name];
      if (rawList == null) {
        for (final entry in purchasedItems.entries) {
          if (entry.key.trim().toLowerCase() == searchName) {
            rawList = entry.value;
            break;
          }
        }
      }
      
      if (rawList is List) {
        newPurchasedList = rawList.map((e) => PurchasedAvatar.fromJson(e as Map<String, dynamic>)).toList();
      }
    }

    final updatedProfile = state.profile?.copyWith(
      avatarConfig: config,
      rawAvatarMap: newAvatarMap,
      rawPurchasedMap: newPurchasedMap,
      purchasedAvatars: newPurchasedList,
      upPoints: finalPoints,
    );
    
    final updatedHome = state.homeData?.copyWith(upPoints: finalPoints);
    
    state = state.copyWith(
      profile: updatedProfile, 
      homeData: updatedHome,
      isLoading: true, // Keep loading true while server syncs
    );

    try {
      // 2. Server Sync
      await _api.updateUser({
        'avatar': newAvatarMap,
        'avatarConfig': newAvatarMap,
        'upPoints': finalPoints,
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _api.updateUser({
        'purchased_avatar': newPurchasedMap,
        'purchasedAvatarItems': newPurchasedMap,
        'purchased_avatar_items': newPurchasedMap,
      });

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      // Revert on failure
      state = originalState.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clear() {
    _profileRequestId++;
    _homeRequestId++;
    state = const UserState();
  }
}
