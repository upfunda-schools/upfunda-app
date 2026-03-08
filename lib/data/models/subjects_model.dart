import 'home_model.dart';

class SubjectsResponse {
  final double overallAccuracy;
  final int pendingWorksheets;
  final List<SubjectSummary> subjects;
  final bool hasTeacher;
  final bool isPremiumUser;

  SubjectsResponse({
    required this.overallAccuracy,
    required this.pendingWorksheets,
    required this.subjects,
    required this.hasTeacher,
    required this.isPremiumUser,
  });

  factory SubjectsResponse.fromJson(Map<String, dynamic> json) =>
      SubjectsResponse(
        overallAccuracy:
            (json['overall_accuracy'] as num?)?.toDouble() ?? 0,
        pendingWorksheets: json['pending_worksheets'] as int? ?? 0,
        subjects: (json['subjects'] as List<dynamic>)
            .map((e) => SubjectSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasTeacher: json['has_teacher'] as bool? ?? false,
        isPremiumUser: json['is_premium_user'] as bool? ?? false,
      );
}
