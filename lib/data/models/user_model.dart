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
        schoolName: json['schoolName'] as String?,
        gender: json['gender'] as String?,
        className: json['className'] as String?,
        sectionName: json['sectionName'] as String?,
        upPoints: json['upPoints'] as int? ?? 0,
        classId: json['classId'] as String?,
        schoolId: json['schoolId'] as String?,
        studentId: json['studentId'] as String?,
        phone: json['phone'] as String?,
        country: json['country'] as String?,
        isPremiumUser: json['isPremiumUser'] as bool? ?? false,
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
