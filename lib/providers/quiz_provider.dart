import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/quiz_model.dart';
import '../data/models/submit_model.dart';
import 'auth_provider.dart';

final quizProvider =
    StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref.read(apiServiceProvider));
});

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
  final List<Question> questions;
  final String currentQuestionId;
  final Map<String, AnswerState> answers;
  final int remainingSeconds;
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
  final Map<String, int> questionStartTime;
  final Map<String, int> questionTimeSpent;

  const QuizState({
    this.testId = '',
    this.testName = '',
    this.questions = const [],
    this.currentQuestionId = '',
    this.answers = const {},
    this.remainingSeconds = 0,
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
  });

  QuizState copyWith({
    String? testId,
    String? testName,
    List<Question>? questions,
    String? currentQuestionId,
    Map<String, AnswerState>? answers,
    int? remainingSeconds,
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
  }) =>
      QuizState(
        testId: testId ?? this.testId,
        testName: testName ?? this.testName,
        questions: questions ?? this.questions,
        currentQuestionId: currentQuestionId ?? this.currentQuestionId,
        answers: answers ?? this.answers,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
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

  int get unansweredCount => questions.length - answeredCount;

  int get reviewCount =>
      answers.values.where((a) => a.status == 'MARKED_FOR_REVIEW').length;

  bool get canUseFiftyFifty => fiftyFiftyUsageCount < fiftyFiftyLimit;

  String get timerDisplay {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final dynamic _api;
  Timer? _timer;

  QuizNotifier(this._api) : super(const QuizState());

  Future<void> initializeQuiz(String testId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.getTestDetails(testId);
      final answers = <String, AnswerState>{};
      for (final q in data.questions) {
        answers[q.questionId] = const AnswerState();
      }
      // Populate already answered
      for (final a in data.alreadyAnswered) {
        answers[a.questionId] = AnswerState(
          selectedOption: a.selectedOptionId,
          status: 'ANSWERED',
          isCorrect: a.isCorrect,
        );
      }

      final limit = (data.pagination.totalQuestions * 0.2).ceil();

      state = state.copyWith(
        testId: data.testId,
        testName: data.testName,
        questions: data.questions,
        currentQuestionId: data.questions.first.questionId,
        answers: answers,
        remainingSeconds: data.timer?.remainingSeconds ?? data.durationSeconds,
        pagination: data.pagination,
        isLoading: false,
        fiftyFiftyLimit: limit,
        fiftyFiftyUsageCount: 0,
        fiftyFiftyUsed: {},
        hiddenOptions: {},
        questionStartTime: {
          data.questions.first.questionId:
              DateTime.now().millisecondsSinceEpoch,
        },
        questionTimeSpent: {},
        checkDetails: false,
        submitResult: null,
      );

      _startTimer();
    } catch (e) {
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
          .map((a) => a.trim().toLowerCase())
          .toList();
      isCorrect =
          expectedAnswers.contains(answer.selectedOption!.trim().toLowerCase());
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
    final result = await _api.submitTest(state.testId);
    state = state.copyWith(submitResult: result);
    return result;
  }

  void goToNext() {
    if (state.isLastQuestion) return;
    final nextId = state.questions[state.currentIndex + 1].questionId;
    setCurrentQuestionId(nextId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
