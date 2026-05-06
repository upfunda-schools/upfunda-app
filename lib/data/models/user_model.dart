import 'dart:convert';
import 'user_avatar_config.dart';

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
  final String? dob;
  final bool isPremiumUser;
  final UserAvatarConfig? avatarConfig;
  final Map<String, dynamic>? rawAvatarMap;
  final Map<String, dynamic>? rawPurchasedMap;
  final List<PurchasedAvatar> purchasedAvatars;

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
    this.dob,
    this.isPremiumUser = false,
    this.avatarConfig,
    this.rawPurchasedMap,
    this.rawAvatarMap,
    this.purchasedAvatars = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final avatar = json['avatar'];
    UserAvatarConfig? config;
    Map<String, dynamic>? rawMap;

    if (avatar != null) {
      Map<String, dynamic>? map;
      if (avatar is String) {
        try {
          final decoded = jsonDecode(avatar);
          if (decoded is Map<String, dynamic>) map = decoded;
        } catch (_) {}
      } else if (avatar is Map<String, dynamic>) {
        map = avatar;
      }

      if (map != null) {
        // Direct config check
        if (map.containsKey('faceColor') || map.containsKey('hairStyle') || map.containsKey('bgColor')) {
          config = UserAvatarConfig.fromJson(map);
        } else {
          // Triple-Key/Resilient Search
          final searchName = name.trim().toLowerCase();
          if (map.containsKey(name)) {
            config = UserAvatarConfig.fromJson(map[name]);
          } else {
            for (final entry in map.entries) {
              if (entry.key.trim().toLowerCase() == searchName) {
                if (entry.value is Map<String, dynamic>) {
                  config = UserAvatarConfig.fromJson(entry.value as Map<String, dynamic>);
                }
                break;
              }
            }
          }
        }
        rawMap = map;
      }
    }

    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      name: name,
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
      dob: json['date_of_birth'] as String? ?? json['dob'] as String?,
      isPremiumUser: json['is_premium_user'] as bool? ?? false,
      avatarConfig: config,
      rawAvatarMap: rawMap,
      rawPurchasedMap: () {
        // Handle potential different field names from different endpoints
        var val = json['purchased_avatar'] ?? 
                  json['purchasedAvatarItems'] ?? 
                  json['purchased_avatar_items'];
        
        if (val == null) return null;

        Map<String, dynamic>? map;
        if (val is String) {
          try {
            var decoded = jsonDecode(val);
            if (decoded is String) decoded = jsonDecode(decoded);
            if (decoded is Map<String, dynamic>) map = decoded;
          } catch (_) {}
        } else if (val is Map<String, dynamic>) {
          map = val;
        }

        return map;
      }(),
      purchasedAvatars: () {
        // Extract the specific list for this user using Triple-Key strategy
        var val = json['purchased_avatar'] ?? 
                  json['purchasedAvatarItems'] ?? 
                  json['purchased_avatar_items'];
        
        Map<String, dynamic>? map;
        if (val is String) {
          try {
            var decoded = jsonDecode(val);
            if (decoded is String) decoded = jsonDecode(decoded);
            if (decoded is Map<String, dynamic>) map = decoded;
          } catch (_) {}
        } else if (val is Map<String, dynamic>) {
          map = val;
        }

        if (map == null) return <PurchasedAvatar>[];

        // Triple-Key Search
        final searchName = name.trim().toLowerCase();
        dynamic list;
        
        if (map.containsKey(name)) {
          list = map[name];
        } else {
          for (final entry in map.entries) {
            if (entry.key.trim().toLowerCase() == searchName) {
              list = entry.value;
              break;
            }
          }
        }

        if (list is List) {
          return list.map((e) => PurchasedAvatar.fromJson(e as Map<String, dynamic>)).toList();
        }
        return <PurchasedAvatar>[];
      }(),
    );
  }

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
    String? schoolName,
    String? gender,
    String? className,
    String? sectionName,
    String? sectionId,
    int? upPoints,
    String? classId,
    String? schoolId,
    String? studentId,
    String? phone,
    String? country,
    String? dob,
    bool? isPremiumUser,
    UserAvatarConfig? avatarConfig,
    Map<String, dynamic>? rawAvatarMap,
    Map<String, dynamic>? rawPurchasedMap,
    List<PurchasedAvatar>? purchasedAvatars,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      schoolName: schoolName ?? this.schoolName,
      gender: gender ?? this.gender,
      className: className ?? this.className,
      sectionName: sectionName ?? this.sectionName,
      sectionId: sectionId ?? this.sectionId,
      upPoints: upPoints ?? this.upPoints,
      classId: classId ?? this.classId,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      dob: dob ?? this.dob,
      isPremiumUser: isPremiumUser ?? this.isPremiumUser,
      avatarConfig: avatarConfig ?? this.avatarConfig,
      rawAvatarMap: rawAvatarMap ?? this.rawAvatarMap,
      rawPurchasedMap: rawPurchasedMap ?? this.rawPurchasedMap,
      purchasedAvatars: purchasedAvatars ?? this.purchasedAvatars,
    );
  }
}

class PurchasedAvatar {
  final String part;
  final String? value;
  final int? price;

  PurchasedAvatar({
    required this.part,
    this.value,
    this.price,
  });

  factory PurchasedAvatar.fromJson(Map<String, dynamic> json) => PurchasedAvatar(
        part: json['part'] as String? ?? json['activePart'] as String? ?? '',
        value: json['value'] as String?,
        price: json['price'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'part': part,
        'value': value,
        'price': price,
      };
}
