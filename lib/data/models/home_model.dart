class HomeResponse {
  final String studentName;
  final String studentId;
  final String schoolId;
  final String sectionId;
  final int upPoints;
  final bool isPremiumUser;
  final HomeStats stats;
  final List<SubjectSummary> subjects;

  HomeResponse({
    required this.studentName,
    required this.studentId,
    required this.schoolId,
    required this.sectionId,
    required this.upPoints,
    required this.isPremiumUser,
    required this.stats,
    required this.subjects,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) => HomeResponse(
        studentName: json['student_name'] as String? ?? '',
        studentId: json['student_id'] as String? ?? '',
        schoolId: json['school_id'] as String? ?? '',
        sectionId: json['section_id'] as String? ?? '',
        upPoints: json['up_points'] as int? ?? 0,
        isPremiumUser: json['is_premium_user'] as bool? ?? false,
        stats: HomeStats.fromJson(json['stats'] as Map<String, dynamic>),
        subjects: (json['subjects'] as List<dynamic>)
            .map((e) => SubjectSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class HomeStats {
  final double overallAccuracy;
  final int totalWorksheets;
  final int solvedWorksheets;
  final int pendingWorksheets;

  HomeStats({
    required this.overallAccuracy,
    required this.totalWorksheets,
    required this.solvedWorksheets,
    required this.pendingWorksheets,
  });

  factory HomeStats.fromJson(Map<String, dynamic> json) => HomeStats(
        overallAccuracy: (json['overall_accuracy'] as num?)?.toDouble() ?? 0,
        totalWorksheets: json['total_worksheets'] as int? ?? 0,
        solvedWorksheets: json['solved_worksheets'] as int? ?? 0,
        pendingWorksheets: json['pending_worksheets'] as int? ?? 0,
      );
}

class SubjectSummary {
  final String subjectId;
  final String name;
  final int solved;
  final int open;
  final double completedPercentage;

  SubjectSummary({
    required this.subjectId,
    required this.name,
    required this.solved,
    required this.open,
    required this.completedPercentage,
  });

  factory SubjectSummary.fromJson(Map<String, dynamic> json) => SubjectSummary(
        subjectId: json['subject_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        solved: json['solved'] as int? ?? 0,
        open: json['open'] as int? ?? 0,
        completedPercentage:
            (json['completed_percentage'] as num?)?.toDouble() ?? 0,
      );
}
