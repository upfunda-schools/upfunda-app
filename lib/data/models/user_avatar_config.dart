class UserAvatarConfig {
  final String? sex;
  final String? faceColor;
  final String? earSize;
  final String? hairColor;
  final String? hairStyle;
  final bool? hairColorRandom;
  final String? hatColor;
  final String? hatStyle;
  final String? eyeStyle;
  final String? glassesStyle;
  final String? noseStyle;
  final String? mouthStyle;
  final String? shirtStyle;
  final String? shirtColor;
  final String? bgColor;
  final bool? isGradient;
  final String? eyeBrowStyle;

  UserAvatarConfig({
    this.sex,
    this.faceColor,
    this.earSize,
    this.hairColor,
    this.hairStyle,
    this.hairColorRandom,
    this.hatColor,
    this.hatStyle,
    this.eyeStyle,
    this.glassesStyle,
    this.noseStyle,
    this.mouthStyle,
    this.shirtStyle,
    this.shirtColor,
    this.bgColor,
    this.isGradient,
    this.eyeBrowStyle,
  });

  factory UserAvatarConfig.fromJson(Map<String, dynamic> json) {
    return UserAvatarConfig(
      sex: json['sex'] as String?,
      faceColor: json['faceColor'] as String?,
      earSize: json['earSize'] as String?,
      hairColor: json['hairColor'] as String?,
      hairStyle: json['hairStyle'] as String?,
      hairColorRandom: json['hairColorRandom'] as bool?,
      hatColor: json['hatColor'] as String?,
      hatStyle: json['hatStyle'] as String?,
      eyeStyle: json['eyeStyle'] as String?,
      glassesStyle: json['glassesStyle'] as String?,
      noseStyle: json['noseStyle'] as String?,
      mouthStyle: json['mouthStyle'] as String?,
      shirtStyle: json['shirtStyle'] as String?,
      shirtColor: json['shirtColor'] as String?,
      bgColor: json['bgColor'] as String?,
      isGradient: json['isGradient'] as bool?,
      eyeBrowStyle: json['eyeBrowStyle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sex != null) 'sex': sex,
      if (faceColor != null) 'faceColor': faceColor,
      if (earSize != null) 'earSize': earSize,
      if (hairColor != null) 'hairColor': hairColor,
      if (hairStyle != null) 'hairStyle': hairStyle,
      if (hairColorRandom != null) 'hairColorRandom': hairColorRandom,
      if (hatColor != null) 'hatColor': hatColor,
      if (hatStyle != null) 'hatStyle': hatStyle,
      if (eyeStyle != null) 'eyeStyle': eyeStyle,
      if (glassesStyle != null) 'glassesStyle': glassesStyle,
      if (noseStyle != null) 'noseStyle': noseStyle,
      if (mouthStyle != null) 'mouthStyle': mouthStyle,
      if (shirtStyle != null) 'shirtStyle': shirtStyle,
      if (shirtColor != null) 'shirtColor': shirtColor,
      if (bgColor != null) 'bgColor': bgColor,
      if (isGradient != null) 'isGradient': isGradient,
      if (eyeBrowStyle != null) 'eyeBrowStyle': eyeBrowStyle,
    };
  }

  UserAvatarConfig copyWith({
    String? sex,
    String? faceColor,
    String? earSize,
    String? hairColor,
    String? hairStyle,
    bool? hairColorRandom,
    String? hatColor,
    String? hatStyle,
    String? eyeStyle,
    String? glassesStyle,
    String? noseStyle,
    String? mouthStyle,
    String? shirtStyle,
    String? shirtColor,
    String? bgColor,
    bool? isGradient,
    String? eyeBrowStyle,
  }) {
    return UserAvatarConfig(
      sex: sex ?? this.sex,
      faceColor: faceColor ?? this.faceColor,
      earSize: earSize ?? this.earSize,
      hairColor: hairColor ?? this.hairColor,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColorRandom: hairColorRandom ?? this.hairColorRandom,
      hatColor: hatColor ?? this.hatColor,
      hatStyle: hatStyle ?? this.hatStyle,
      eyeStyle: eyeStyle ?? this.eyeStyle,
      glassesStyle: glassesStyle ?? this.glassesStyle,
      noseStyle: noseStyle ?? this.noseStyle,
      mouthStyle: mouthStyle ?? this.mouthStyle,
      shirtStyle: shirtStyle ?? this.shirtStyle,
      shirtColor: shirtColor ?? this.shirtColor,
      bgColor: bgColor ?? this.bgColor,
      isGradient: isGradient ?? this.isGradient,
      eyeBrowStyle: eyeBrowStyle ?? this.eyeBrowStyle,
    );
  }
}
