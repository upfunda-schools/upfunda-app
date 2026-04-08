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
        subjectId: (json['subject_id'] ?? json['id'] ?? '') as String,
        subjectName: (json['subject_name'] ?? json['name'] ?? '') as String,
        teacherGated: (json['has_teacher'] ?? json['teacher_gated']) as bool? ?? false,
        topics: (json['topics'] as List<dynamic>)
            .map((e) => Topic.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Topic {
  final String id;
  final String name;
  final String status; // in_progress, completed, not_started
  final double progressPercentage;
  final bool isPremium;
  final List<TestInfo> tests;
  final String? projectDetails; 

  Topic({
    required this.id,
    required this.name,
    required this.status,
    required this.progressPercentage,
    required this.isPremium,
    required this.tests,
    this.projectDetails,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
     // Support both old and new JSON keys to avoid breaking the app
     final id = (json['topic_id'] ?? json['test_id'] ?? json['id'] ?? '') as String;
     final status = json['status'] as String? ?? (json['is_completed'] == true ? 'completed' : 'not_started');
     final progress = (json['progress_percentage'] as num?)?.toDouble() ?? (json['is_completed'] == true ? 100.0 : 0.0);
     
     return Topic(
        id: id,
        name: (json['topic_name'] ?? json['test_name'] ?? json['name'] ?? '') as String,
        status: status,
        progressPercentage: progress,
        isPremium: json['is_premium'] as bool? ?? false,
        tests: (json['tests'] as List<dynamic>?)
                ?.map((e) => TestInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        projectDetails: json['project_details'] as String?,
      );
  }
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
        testId: (json['test_id'] ?? json['id'] ?? '') as String,
        level: json['level'] as int? ?? 1,
        status: json['status'] as String? ?? 'not_started',
      );
}
