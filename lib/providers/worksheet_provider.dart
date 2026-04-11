import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/subjects_model.dart';
import 'auth_provider.dart';

final worksheetProvider =
    StateNotifierProvider<WorksheetNotifier, WorksheetState>((ref) {
  return WorksheetNotifier(ref.read(apiServiceProvider));
});

class WorksheetState {
  final SubjectsResponse? data;
  final bool isLoading;
  final String? error;

  const WorksheetState({this.data, this.isLoading = false, this.error});

  WorksheetState copyWith({
    SubjectsResponse? data,
    bool? isLoading,
    String? error,
  }) =>
      WorksheetState(
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class WorksheetNotifier extends StateNotifier<WorksheetState> {
  final dynamic _api;

  WorksheetNotifier(this._api) : super(const WorksheetState());

  void clear() {
    state = const WorksheetState();
  }

  Future<void> loadSubjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.getSubjects();
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
