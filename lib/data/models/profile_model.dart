import 'dart:convert';
import 'user_avatar_config.dart';

class StudentProfile {
  final String profileId;
  final String studentId;
  final String name;
  final String className;
  final String classGrade;
  final String schoolName;
  final String? sectionName;
  final UserAvatarConfig? avatarConfig;

  StudentProfile({
    required this.profileId,
    required this.studentId,
    required this.name,
    required this.className,
    required this.classGrade,
    required this.schoolName,
    this.sectionName,
    this.avatarConfig,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final avatar = json['avatar'];
    UserAvatarConfig? config;

    if (avatar != null) {
      Map<String, dynamic>? decoded;
      if (avatar is String) {
        try {
          final d = jsonDecode(avatar);
          if (d is Map<String, dynamic>) decoded = d;
        } catch (_) {}
      } else if (avatar is Map<String, dynamic>) {
        decoded = avatar;
      }

      if (decoded != null) {
        if (decoded.containsKey(name)) {
          config = UserAvatarConfig.fromJson(decoded[name] as Map<String, dynamic>);
        } else if (decoded.containsKey('faceColor') || decoded.containsKey('hairStyle') || decoded.containsKey('bgColor')) {
          config = UserAvatarConfig.fromJson(decoded);
        } else {
          final searchName = name.trim().toLowerCase();
          for (final entry in decoded.entries) {
            if (entry.key.trim().toLowerCase() == searchName) {
              if (entry.value is Map<String, dynamic>) {
                config = UserAvatarConfig.fromJson(entry.value as Map<String, dynamic>);
              }
              break;
            }
          }
        }
      }
    }

    return StudentProfile(
      profileId: json['profile_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      name: name,
      className: json['class_name'] as String? ?? '',
      classGrade: json['class_grade'] as String? ?? '',
      schoolName: json['school_name'] as String? ?? '',
      sectionName: json['section_name'] as String?,
      avatarConfig: config,
    );
  }
}
