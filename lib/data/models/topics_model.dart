class TopicsResponse {
  final String subjectId;
  final String subjectName;
  final bool teacherGated;
  final List<Topic> topics;

  TopicsResponse({
    required this.subjectId,
    required this.subjectName,
    required this.teacherGated,
    required this.topics,
  });

  factory TopicsResponse.fromJson(Map<String, dynamic> json) => TopicsResponse(
        subjectId: json['subject_id'] as String? ?? '',
        subjectName: json['subject_name'] as String? ?? '',
        teacherGated: json['teacher_gated'] as bool? ?? false,
        topics: (json['topics'] as List<dynamic>)
            .map((e) => Topic.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Topic {
  final String topicId;
  final String name;
  final bool isPremium;
  final String status; // in_progress, completed, not_started
  final double progressPercentage;
  final List<TestInfo> tests;

  Topic({
    required this.topicId,
    required this.name,
    required this.isPremium,
    required this.status,
    required this.progressPercentage,
    required this.tests,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        topicId: json['topic_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        isPremium: json['is_premium'] as bool? ?? false,
        status: json['status'] as String? ?? 'not_started',
        progressPercentage:
            (json['progress_percentage'] as num?)?.toDouble() ?? 0,
        tests: (json['tests'] as List<dynamic>?)
                ?.map((e) => TestInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class TestInfo {
  final String testId;
  final int level;
  final String status; // completed, not_started

  TestInfo({
    required this.testId,
    required this.level,
    required this.status,
  });

  factory TestInfo.fromJson(Map<String, dynamic> json) => TestInfo(
        testId: json['test_id'] as String? ?? '',
        level: json['level'] as int? ?? 1,
        status: json['status'] as String? ?? 'not_started',
      );
}
