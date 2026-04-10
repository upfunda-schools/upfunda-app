import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/submit_model.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref);
});

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;

  LeaderboardState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref _ref;

  LeaderboardNotifier(this._ref) : super(LeaderboardState());

  Future<void> loadLeaderboard() async {
    final api = _ref.read(apiServiceProvider);
    final user = _ref.read(userProvider).profile;

    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      List<LeaderboardEntry> entries;
      if (user.sectionId == null || user.sectionId!.isEmpty) {
        entries = await api.getClassLeaderBoard(
          type: 'school',
          schoolId: user.schoolId ?? '',
          classId: user.classId ?? '',
        );
      } else {
        entries = await api.getLeaderBoard(
          type: 'school',
          schoolId: user.schoolId ?? '',
          classId: user.classId ?? '',
          sectionId: user.sectionId ?? '',
        );
      }
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
