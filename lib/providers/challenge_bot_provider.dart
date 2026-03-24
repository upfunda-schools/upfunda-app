import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/challenge_model.dart';
import '../data/services/api_service.dart';
import 'auth_provider.dart';

class ChallengeBotState {
  final BotChallengeSession? session;
  final int currentIndex;
  final Map<String, String> answers; // questionId -> selectedOptionId
  final Map<String, int> timings; // questionId -> seconds
  final bool isLoading;
  final String? error;

  const ChallengeBotState({
    this.session,
    this.currentIndex = 0,
    this.answers = const {},
    this.timings = const {},
    this.isLoading = false,
    this.error,
  });

  ChallengeBotState copyWith({
    BotChallengeSession? session,
    int? currentIndex,
    Map<String, String>? answers,
    Map<String, int>? timings,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      ChallengeBotState(
        session: session ?? this.session,
        currentIndex: currentIndex ?? this.currentIndex,
        answers: answers ?? this.answers,
        timings: timings ?? this.timings,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );

  bool get isFinished =>
      session != null && currentIndex >= session!.questions.length;

  int get userScore {
    if (session == null) return 0;
    return session!.questions
        .where((q) => answers[q.questionId] == q.correctOptionId)
        .length;
  }

  int get botScore {
    if (session == null) return 0;
    return session!.questions
        .where((q) => q.botBehavior.willAnswerCorrectly)
        .length;
  }
}

class ChallengeBotNotifier extends StateNotifier<ChallengeBotState> {
  final ApiService _api;

  ChallengeBotNotifier(this._api) : super(const ChallengeBotState());

  Future<void> startChallenge() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      session: null,
      currentIndex: 0,
      answers: {},
      timings: {},
    );
    try {
      final session = await _api.startChallenge();
      state = state.copyWith(session: session, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void submitAnswer(String questionId, String optionId, int timeTaken) {
    final newAnswers = Map<String, String>.from(state.answers)
      ..[questionId] = optionId;
    final newTimings = Map<String, int>.from(state.timings)
      ..[questionId] = timeTaken;
    state = state.copyWith(
      answers: newAnswers,
      timings: newTimings,
      currentIndex: state.currentIndex + 1,
    );
  }

  void reset() {
    state = const ChallengeBotState();
  }
}

final challengeBotProvider =
    StateNotifierProvider<ChallengeBotNotifier, ChallengeBotState>((ref) {
  return ChallengeBotNotifier(ref.read(apiServiceProvider));
});
