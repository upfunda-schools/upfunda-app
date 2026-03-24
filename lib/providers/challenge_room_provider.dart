import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/challenge_room_model.dart';
import '../data/services/api_service.dart';
import 'auth_provider.dart';

class ChallengeRoomState {
  final String? roomId;
  final String? roomCode;
  final String status; // idle | waiting | active | completed
  final ChallengeRoomResult? result;
  final List<RoomChallengeQuestion> questions;
  final int currentIndex;
  final int myAnsweredCount;
  final int opponentAnsweredCount;
  final bool isLoading;
  final String? error;
  final bool isHost; // true = created the room, false = joined

  const ChallengeRoomState({
    this.roomId,
    this.roomCode,
    this.status = 'idle',
    this.result,
    this.questions = const [],
    this.currentIndex = 0,
    this.myAnsweredCount = 0,
    this.opponentAnsweredCount = 0,
    this.isLoading = false,
    this.error,
    this.isHost = false,
  });

  ChallengeRoomState copyWith({
    String? roomId,
    String? roomCode,
    String? status,
    ChallengeRoomResult? result,
    List<RoomChallengeQuestion>? questions,
    int? currentIndex,
    int? myAnsweredCount,
    int? opponentAnsweredCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isHost,
  }) =>
      ChallengeRoomState(
        roomId: roomId ?? this.roomId,
        roomCode: roomCode ?? this.roomCode,
        status: status ?? this.status,
        result: result ?? this.result,
        questions: questions ?? this.questions,
        currentIndex: currentIndex ?? this.currentIndex,
        myAnsweredCount: myAnsweredCount ?? this.myAnsweredCount,
        opponentAnsweredCount:
            opponentAnsweredCount ?? this.opponentAnsweredCount,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isHost: isHost ?? this.isHost,
      );

  bool get isQuizFinished =>
      questions.isNotEmpty && currentIndex >= questions.length;
}

class ChallengeRoomNotifier extends StateNotifier<ChallengeRoomState> {
  final ApiService _api;
  Timer? _pollTimer;

  ChallengeRoomNotifier(this._api) : super(const ChallengeRoomState());

  Future<void> createRoom() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _api.createChallengeRoom();
      state = state.copyWith(
        roomId: created.roomId,
        roomCode: created.roomCode,
        status: created.status,
        isHost: true,
        isLoading: false,
      );
      _startPolling();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> joinRoom(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final joined = await _api.joinChallengeRoom(code);
      state = state.copyWith(
        roomId: joined.roomId,
        status: joined.status,
        isHost: false,
        isLoading: false,
      );
      _startPolling();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ChallengeRoomResult?> startRoom() async {
    final roomId = state.roomId;
    if (roomId == null) return null;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _api.startChallengeRoom(roomId);
      _stopPolling();
      state = state.copyWith(
        status: 'active',
        result: result,
        questions: result.questions,
        currentIndex: 0,
        isLoading: false,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<SingleAnswerResult?> submitAnswer(
    String questionId,
    String selectedOptionId,
    int timeTakenSeconds,
  ) async {
    final roomId = state.roomId;
    if (roomId == null) return null;
    try {
      final result = await _api.submitChallengeRoomAnswer(
        roomId: roomId,
        questionId: questionId,
        selectedOptionId: selectedOptionId,
        timeTakenSeconds: timeTakenSeconds,
      );
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        myAnsweredCount: result.answeredCount,
      );
      if (result.finished) {
        _startPolling(); // poll until opponent also finishes
      }
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> quit() async {
    final roomId = state.roomId;
    if (roomId == null) return;
    _stopPolling();
    try {
      await _api.quitChallengeRoom(roomId);
    } catch (_) {}
    reset();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _poll() async {
    final roomId = state.roomId;
    if (roomId == null) return;
    try {
      final result = await _api.getChallengeRoomResult(roomId);

      // Fix: host is always players[0], guest is always players[1]
      final opponentIndex = state.isHost ? 1 : 0;
      final opponentAnswered = result.players.length > opponentIndex
          ? result.players[opponentIndex].answered
          : 0;

      state = state.copyWith(
        status: result.status,
        result: result,
        opponentAnsweredCount: opponentAnswered,
        questions: result.questions.isNotEmpty
            ? result.questions
            : state.questions,
      );

      if (result.status == 'completed') {
        _stopPolling();
      } else if (result.status == 'active' && state.questions.isEmpty) {
        // Guest detected room became active via polling but has no questions.
        // GetResult never returns questions — call startRoom to fetch them.
        _stopPolling();
        await startRoom();
      }
    } catch (_) {
      // Ignore poll errors silently
    }
  }

  void reset() {
    _stopPolling();
    state = const ChallengeRoomState();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

final challengeRoomProvider =
    StateNotifierProvider<ChallengeRoomNotifier, ChallengeRoomState>((ref) {
  return ChallengeRoomNotifier(ref.read(apiServiceProvider));
});
