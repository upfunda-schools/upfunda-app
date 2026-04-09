class StudentProfile {
  final String profileId;
  final String studentId;
  final String name;
  final String className;
  final String classGrade;
  final String schoolName;
  final String? sectionName;

  StudentProfile({
    required this.profileId,
    required this.studentId,
    required this.name,
    required this.className,
    required this.classGrade,
    required this.schoolName,
    this.sectionName,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        profileId: json['profile_id'] as String? ?? '',
        studentId: json['student_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        className: json['class_name'] as String? ?? '',
        classGrade: json['class_grade'] as String? ?? '',
        schoolName: json['school_name'] as String? ?? '',
        sectionName: json['section_name'] as String?,
      );
}
