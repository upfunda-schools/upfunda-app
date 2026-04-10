class LoginResponse {
  final String customToken;
  final String role;

  LoginResponse({required this.customToken, required this.role});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        customToken: json['custom_token'] as String,
        role: json['role'] as String,
      );
}

class UserProfile {
  final String id;
  final String email;
  final String role;
  final String name;
  final String? schoolName;
  final String? gender;
  final String? className;
  final String? sectionName;
  final String? sectionId;
  final int upPoints;
  final String? classId;
  final String? schoolId;
  final String? studentId;
  final String? phone;
  final String? country;
  final bool isPremiumUser;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.schoolName,
    this.gender,
    this.className,
    this.sectionName,
    this.sectionId,
    this.upPoints = 0,
    this.classId,
    this.schoolId,
    this.studentId,
    this.phone,
    this.country,
    this.isPremiumUser = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'student',
        name: json['name'] as String? ?? '',
        schoolName: json['school_name'] as String?,
        gender: json['gender'] as String?,
        className: json['class_name'] as String?,
        sectionName: json['section_name'] as String?,
        sectionId: json['section_id'] as String?,
        upPoints: json['up_points'] as int? ?? 0,
        classId: json['class_id'] as String?,
        schoolId: json['school_id'] as String?,
        studentId: json['student_id'] as String?,
        phone: json['phone'] as String?,
        country: json['country'] as String?,
        isPremiumUser: json['is_premium_user'] as bool? ?? false,
      );

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
