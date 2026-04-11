import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/quiz_model.dart';
import '../data/models/submit_model.dart';
import 'auth_provider.dart';

final quizProvider =
    StateNotifierProvider.autoDispose<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref.read(apiServiceProvider));
});

final quizMuteProvider = StateProvider<bool>((ref) => false);

class AnswerState {
  final String? selectedOption;
  final String status; // ANSWERED, NOT_ANSWERED, MARKED_FOR_REVIEW
  final bool isCorrect;
  final bool usedFiftyFifty;

  const AnswerState({
    this.selectedOption,
    this.status = 'NOT_ANSWERED',
    this.isCorrect = false,
    this.usedFiftyFifty = false,
  });

  AnswerState copyWith({
    String? selectedOption,
    String? status,
    bool? isCorrect,
    bool? usedFiftyFifty,
  }) =>
      AnswerState(
        selectedOption: selectedOption ?? this.selectedOption,
        status: status ?? this.status,
        isCorrect: isCorrect ?? this.isCorrect,
        usedFiftyFifty: usedFiftyFifty ?? this.usedFiftyFifty,
      );
}

class QuizState {
  final String testId;
  final String testName;
  final String subjectId;
  final List<Question> questions;
  final String currentQuestionId;
  final Map<String, AnswerState> answers;
  final int remainingSeconds;
  final int totalDurationSeconds;
  final bool checkDetails;
  final Pagination? pagination;
  final bool isLoading;
  final String? error;
  final SubmitTestResponse? submitResult;

  // 50-50
  final Map<String, bool> fiftyFiftyUsed;
  final Map<String, List<String>> hiddenOptions;
  final int fiftyFiftyUsageCount;
  final int fiftyFiftyLimit;

  // Time tracking
  final bool isTimed; // true only if server sent non-zero duration
  final Map<String, int> questionStartTime;
  final Map<String, int> questionTimeSpent;

  // Server reported this test as timed out (HTTP 409)
  final bool isTimedOut;

  const QuizState({
    this.testId = '',
    this.testName = '',
    this.subjectId = '',
    this.questions = const [],
    this.currentQuestionId = '',
    this.answers = const {},
    this.remainingSeconds = 0,
    this.totalDurationSeconds = 0,
    this.isTimed = false,
    this.checkDetails = false,
    this.pagination,
    this.isLoading = false,
    this.error,
    this.submitResult,
    this.fiftyFiftyUsed = const {},
    this.hiddenOptions = const {},
    this.fiftyFiftyUsageCount = 0,
    this.fiftyFiftyLimit = 0,
    this.questionStartTime = const {},
    this.questionTimeSpent = const {},
    this.isTimedOut = false,
  });

  QuizState copyWith({
    String? testId,
    String? testName,
    String? subjectId,
    List<Question>? questions,
    String? currentQuestionId,
    Map<String, AnswerState>? answers,
    int? remainingSeconds,
    int? totalDurationSeconds,
    bool? isTimed,
    bool? checkDetails,
    Pagination? pagination,
    bool? isLoading,
    String? error,
    SubmitTestResponse? submitResult,
    Map<String, bool>? fiftyFiftyUsed,
    Map<String, List<String>>? hiddenOptions,
    int? fiftyFiftyUsageCount,
    int? fiftyFiftyLimit,
    Map<String, int>? questionStartTime,
    Map<String, int>? questionTimeSpent,
    bool? isTimedOut,
  }) =>
      QuizState(
        testId: testId ?? this.testId,
        testName: testName ?? this.testName,
        subjectId: subjectId ?? this.subjectId,
        questions: questions ?? this.questions,
        currentQuestionId: currentQuestionId ?? this.currentQuestionId,
        answers: answers ?? this.answers,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
        isTimed: isTimed ?? this.isTimed,
        checkDetails: checkDetails ?? this.checkDetails,
        pagination: pagination ?? this.pagination,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        submitResult: submitResult ?? this.submitResult,
        fiftyFiftyUsed: fiftyFiftyUsed ?? this.fiftyFiftyUsed,
        hiddenOptions: hiddenOptions ?? this.hiddenOptions,
        fiftyFiftyUsageCount: fiftyFiftyUsageCount ?? this.fiftyFiftyUsageCount,
        fiftyFiftyLimit: fiftyFiftyLimit ?? this.fiftyFiftyLimit,
        questionStartTime: questionStartTime ?? this.questionStartTime,
        questionTimeSpent: questionTimeSpent ?? this.questionTimeSpent,
        isTimedOut: isTimedOut ?? this.isTimedOut,
      );

  Question? get currentQuestion {
    try {
      return questions.firstWhere((q) => q.questionId == currentQuestionId);
    } catch (_) {
      return questions.isNotEmpty ? questions.first : null;
    }
  }

  int get currentIndex {
    final idx =
        questions.indexWhere((q) => q.questionId == currentQuestionId);
    return idx >= 0 ? idx : 0;
  }

  bool get isLastQuestion => currentIndex == questions.length - 1;

  int get answeredCount =>
      answers.values.where((a) => a.status == 'ANSWERED').length;

  int get correctCount => answers.values.where((a) => a.isCorrect).length;

  int get incorrectCount =>
      answers.values.where((a) => a.status == 'ANSWERED' && !a.isCorrect).length;

  int get unansweredCount => questions.length - answeredCount;

  int get reviewCount =>
      answers.values.where((a) => a.status == 'MARKED_FOR_REVIEW').length;

  bool get canUseFiftyFifty => fiftyFiftyUsageCount < fiftyFiftyLimit;

  bool get hasTimer => remainingSeconds > 0;

  String get timerDisplay {
    if (!hasTimer) return '\u221E'; // ∞
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final dynamic _api;
  Timer? _timer;
  Timer? _heartbeatTimer;

  QuizNotifier(this._api) : super(const QuizState());

  Future<void> initializeQuiz(String testId, {String subjectId = ''}) async {
    state = state.copyWith(isLoading: true, error: null, isTimedOut: false);
    try {
      // Page 1 gives us alreadyAnswered (all pages) and pagination info
      final TestDetailsResponse firstPage =
          await _api.getTestDetails(testId, page: 1);
      final pageSize = firstPage.pagination.pageSize;
      final totalQuestions = firstPage.pagination.totalQuestions;
      final answeredCount = firstPage.alreadyAnswered.length;
      final allAnswered = totalQuestions > 0 && answeredCount >= totalQuestions;

      // Compute which page to land on for resume
      int targetPage = 1;
      TestDetailsResponse data = firstPage;
      if (!allAnswered && answeredCount > 0) {
        targetPage = (answeredCount ~/ pageSize) + 1;
        if (targetPage > 1 && targetPage <= firstPage.pagination.totalPages) {
          data = await _api.getTestDetails(testId, page: targetPage);
        }
      }

      // Build answers map: initialize current page + restore alreadyAnswered
      final answeredIds =
          firstPage.alreadyAnswered.map((a) => a.questionId).toSet();
      final answers = <String, AnswerState>{};
      for (final q in data.questions) {
        answers[q.questionId] = const AnswerState();
      }
      for (final a in firstPage.alreadyAnswered) {
        answers[a.questionId] = AnswerState(
          selectedOption: a.selectedOptionId,
          status: 'ANSWERED',
          isCorrect: a.isCorrect,
        );
      }

      // Land on first unanswered question on the target page
      String currentQuestionId;
      if (data.questions.isEmpty) {
        currentQuestionId = '';
      } else if (allAnswered) {
        currentQuestionId = data.questions.first.questionId;
      } else {
        final firstUnanswered = data.questions.firstWhere(
          (q) => !answeredIds.contains(q.questionId),
          orElse: () => data.questions.first,
        );
        currentQuestionId = firstUnanswered.questionId;
      }

      // If quiz was paused, resume it so the backend recalculates end time
      if (firstPage.timer?.isPaused == true) {
        try {
          await _api.resumeTest(testId);
        } catch (_) {}
      }

      final limit = (totalQuestions * 0.2).ceil();
      final remainingSeconds =
          firstPage.timer?.remainingSeconds ?? firstPage.durationSeconds;

      state = state.copyWith(
        testId: data.testId,
        testName: data.testName,
        subjectId: subjectId,
        questions: data.questions,
        currentQuestionId: currentQuestionId,
        answers: answers,
        remainingSeconds: remainingSeconds,
        isTimed: remainingSeconds > 0,
        totalDurationSeconds: firstPage.durationSeconds,
        pagination: data.pagination,
        isLoading: false,
        fiftyFiftyLimit: limit,
        fiftyFiftyUsageCount: 0,
        fiftyFiftyUsed: {},
        hiddenOptions: {},
        questionStartTime: currentQuestionId.isNotEmpty
            ? {currentQuestionId: DateTime.now().millisecondsSinceEpoch}
            : {},
        questionTimeSpent: {},
        checkDetails: false,
        submitResult: null,
      );

      if (state.remainingSeconds > 0) {
        _startTimer();
        _startHeartbeat();
      }
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        final msg = (data is Map ? data['error'] as String? : null) ?? '';
        if (msg == 'test has timed out') {
          state = state.copyWith(isLoading: false, isTimedOut: true);
          return;
        }
      }
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 0) {
        _timer?.cancel();
        return;
      }
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (state.testId.isEmpty) return;
      try {
        await _api.sendHeartbeat(state.testId);
      } catch (_) {}
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> resumeQuiz() async {
    if (state.testId.isEmpty) return;
    try {
      await _api.resumeTest(state.testId);
      final data = await _api.getTestDetails(state.testId, page: 1);
      final remaining = data.timer?.remainingSeconds ?? state.remainingSeconds;
      state = state.copyWith(remainingSeconds: remaining);
      if (remaining > 0) {
        _startTimer();
        _startHeartbeat();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopHeartbeat();
    super.dispose();
  }

  void answerQuestion(String questionId, String option) {
    final answers = Map<String, AnswerState>.from(state.answers);
    answers[questionId] = AnswerState(
      selectedOption: option,
      status: 'ANSWERED',
    );
    state = state.copyWith(answers: answers);
  }

  void setCurrentQuestionId(String questionId) {
    // Record time spent on current question
    final timeSpent = Map<String, int>.from(state.questionTimeSpent);
    final startTimes = Map<String, int>.from(state.questionStartTime);

    if (startTimes.containsKey(state.currentQuestionId)) {
      final elapsed = DateTime.now().millisecondsSinceEpoch -
          startTimes[state.currentQuestionId]!;
      timeSpent[state.currentQuestionId] =
          (timeSpent[state.currentQuestionId] ?? 0) + (elapsed ~/ 1000);
    }

    startTimes[questionId] = DateTime.now().millisecondsSinceEpoch;

    state = state.copyWith(
      currentQuestionId: questionId,
      checkDetails: false,
      questionStartTime: startTimes,
      questionTimeSpent: timeSpent,
    );
  }

  void setCheckDetails(bool value) {
    state = state.copyWith(checkDetails: value);
  }

  bool checkAnswer(String questionId) {
    final question =
        state.questions.firstWhere((q) => q.questionId == questionId);
    final answer = state.answers[questionId];
    if (answer == null || answer.selectedOption == null) return false;

    bool isCorrect;
    if (question.isFillType) {
      final expectedAnswers = question.solution!.answer
          .split('||')
          .map((a) => a.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim().toLowerCase())
          .toList();
      final userResponse = (answer.selectedOption ?? '').trim().toLowerCase();
      isCorrect = expectedAnswers.contains(userResponse);
    } else {
      isCorrect = answer.selectedOption == question.solution?.correctOptionId;
    }

    final answers = Map<String, AnswerState>.from(state.answers);
    answers[questionId] = answer.copyWith(isCorrect: isCorrect);
    state = state.copyWith(answers: answers, checkDetails: true);
    return isCorrect;
  }

  void useFiftyFifty(String questionId) {
    if (!state.canUseFiftyFifty) return;
    if (state.fiftyFiftyUsed[questionId] == true) return;

    final question =
        state.questions.firstWhere((q) => q.questionId == questionId);
    if (question.isFillType) return;

    final correctId = question.solution?.correctOptionId;
    final wrongOptions = question.options
        .where((o) => o.optionId != correctId)
        .map((o) => o.optionId)
        .toList();
    wrongOptions.shuffle();
    final toHide = wrongOptions.take(2).toList();

    final hidden = Map<String, List<String>>.from(state.hiddenOptions);
    hidden[questionId] = toHide;

    final used = Map<String, bool>.from(state.fiftyFiftyUsed);
    used[questionId] = true;

    final answers = Map<String, AnswerState>.from(state.answers);
    answers[questionId] =
        (answers[questionId] ?? const AnswerState()).copyWith(usedFiftyFifty: true);

    state = state.copyWith(
      hiddenOptions: hidden,
      fiftyFiftyUsed: used,
      fiftyFiftyUsageCount: state.fiftyFiftyUsageCount + 1,
      answers: answers,
    );
  }

  void markForReview(String questionId) {
    final answers = Map<String, AnswerState>.from(state.answers);
    final current = answers[questionId] ?? const AnswerState();
    answers[questionId] = current.copyWith(
      status: current.status == 'MARKED_FOR_REVIEW'
          ? (current.selectedOption != null ? 'ANSWERED' : 'NOT_ANSWERED')
          : 'MARKED_FOR_REVIEW',
    );
    state = state.copyWith(answers: answers);
  }

  int _getTimeSpent(String questionId) {
    final startTimes = state.questionStartTime;
    final timeSpent = state.questionTimeSpent;
    var total = timeSpent[questionId] ?? 0;
    if (startTimes.containsKey(questionId)) {
      total += (DateTime.now().millisecondsSinceEpoch -
              startTimes[questionId]!) ~/
          1000;
    }
    return total;
  }

  Future<void> submitAnswer(String questionId) async {
    final answer = state.answers[questionId];
    if (answer == null) return;

    final question =
        state.questions.firstWhere((q) => q.questionId == questionId);

    await _api.submitAnswer(
      state.testId,
      SubmitAnswerRequest(
        questionId: questionId,
        type: question.type,
        selectedOptionId: answer.selectedOption ?? '',
        isCorrect: answer.isCorrect,
        timeTakenSeconds: _getTimeSpent(questionId),
        usedFiftyFifty: answer.usedFiftyFifty,
      ),
    );
  }

  Future<SubmitTestResponse> submitTest() async {
    _timer?.cancel();
    _stopHeartbeat();
    final result = await _api.submitTest(state.testId);
    state = state.copyWith(submitResult: result);
    return result;
  }

  Future<void> pauseQuiz() async {
    _timer?.cancel();
    _stopHeartbeat();
    try {
      await _api.pauseTest(state.testId);
    } catch (_) {}
  }

  void goToNext() {
    if (state.isLastQuestion) return;
    final nextId = state.questions[state.currentIndex + 1].questionId;
    setCurrentQuestionId(nextId);
  }

  Future<void> loadNextPage() async {
    final pagination = state.pagination;
    if (pagination == null || !pagination.hasNext) return;
    try {
      final nextPage = pagination.currentPage + 1;
      final data = await _api.getTestDetails(state.testId, page: nextPage);
      final answers = Map<String, AnswerState>.from(state.answers);
      for (final q in data.questions) {
        answers.putIfAbsent(q.questionId, () => const AnswerState());
      }
      state = state.copyWith(
        questions: data.questions,
        currentQuestionId: data.questions.first.questionId,
        answers: answers,
        pagination: data.pagination,
        checkDetails: false,
      );
    } catch (_) {}
  }

}
