import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/topics_model.dart';
import 'auth_provider.dart';

final testListProvider =
    StateNotifierProvider.autoDispose<TestListNotifier, TestListState>((ref) {
  return TestListNotifier(ref.read(apiServiceProvider));
});

class TestListState {
  final TopicsResponse? data;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const TestListState({
    this.data,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  TestListState copyWith({
    TopicsResponse? data,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) =>
      TestListState(
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  List<Topic> get filteredTopics {
    if (data == null) return [];
    if (searchQuery.isEmpty) return data!.topics;
    return data!.topics
        .where(
            (t) => t.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }
}

class TestListNotifier extends StateNotifier<TestListState> {
  final dynamic _api;

  TestListNotifier(this._api) : super(const TestListState());

  Future<void> loadTopics(String subjectId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.getTopics(subjectId);
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
