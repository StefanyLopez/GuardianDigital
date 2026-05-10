class ProfileModel {
  final String id;
  final String familyId;
  final String name;
  final String ageRange;
  final int avatarId;
  final List<String> goals;
  final int autonomyLevel;
  final int streakDays;
  final DateTime? lastActive;
  final Map<String, dynamic> visibilityConfig;
  final DateTime createdAt;

  // Luma cosmetics
  final int equippedBodyColor;
  final int equippedAccessory;
  final int equippedEyes;
  final int lumaPoints;
  final List<String> unlockedCosmetics;
  final bool hadNightUsage;

  const ProfileModel({
    required this.id,
    required this.familyId,
    required this.name,
    required this.ageRange,
    required this.avatarId,
    required this.goals,
    required this.autonomyLevel,
    required this.streakDays,
    this.lastActive,
    required this.visibilityConfig,
    required this.createdAt,
    this.equippedBodyColor = 0,
    this.equippedAccessory = 0,
    this.equippedEyes = 0,
    this.lumaPoints = 0,
    this.unlockedCosmetics = const [],
    this.hadNightUsage = false,
  });

  bool get isTeen => ageRange == '13-17';
  bool get isKid  => ageRange == '8-12';
  int  get sessionMessageLimit  => isTeen ? 12 : 8;
  int  get sessionCooldownHours => isTeen ? 1 : 2;

  String get avatarEmoji {
    const emojis = ['🦁','🐼','🦊','🐬','🦋','🌟'];
    return emojis[avatarId.clamp(0, emojis.length - 1)];
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id:                  json['id'] as String,
    familyId:            json['family_id'] as String,
    name:                json['name'] as String,
    ageRange:            json['age_range'] as String,
    avatarId:            json['avatar_id'] as int? ?? 0,
    goals:               List<String>.from(json['goals'] ?? []),
    autonomyLevel:       json['autonomy_level'] as int? ?? 1,
    streakDays:          json['streak_days'] as int? ?? 0,
    lastActive:          json['last_active'] != null ? DateTime.parse(json['last_active'] as String) : null,
    visibilityConfig:    Map<String, dynamic>.from(json['visibility_config'] ?? {}),
    createdAt:           DateTime.parse(json['created_at'] as String),
    equippedBodyColor:   json['equipped_body_color'] as int? ?? 0,
    equippedAccessory:   json['equipped_accessory'] as int? ?? 0,
    equippedEyes:        json['equipped_eyes'] as int? ?? 0,
    lumaPoints:          json['luma_points'] as int? ?? 0,
    unlockedCosmetics:   List<String>.from(json['unlocked_cosmetics'] ?? ['body_mint','acc_none','eyes_normal']),
    hadNightUsage:       json['had_night_usage'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'family_id': familyId, 'name': name, 'age_range': ageRange,
    'avatar_id': avatarId, 'goals': goals, 'autonomy_level': autonomyLevel,
    'streak_days': streakDays, 'last_active': lastActive?.toIso8601String(),
    'visibility_config': visibilityConfig, 'created_at': createdAt.toIso8601String(),
    'equipped_body_color': equippedBodyColor, 'equipped_accessory': equippedAccessory,
    'equipped_eyes': equippedEyes, 'luma_points': lumaPoints,
    'unlocked_cosmetics': unlockedCosmetics, 'had_night_usage': hadNightUsage,
  };

  ProfileModel copyWith({
    String? id, String? familyId, String? name, String? ageRange,
    int? avatarId, List<String>? goals, int? autonomyLevel, int? streakDays,
    DateTime? lastActive, Map<String, dynamic>? visibilityConfig, DateTime? createdAt,
    int? equippedBodyColor, int? equippedAccessory, int? equippedEyes,
    int? lumaPoints, List<String>? unlockedCosmetics, bool? hadNightUsage,
  }) => ProfileModel(
    id: id ?? this.id, familyId: familyId ?? this.familyId,
    name: name ?? this.name, ageRange: ageRange ?? this.ageRange,
    avatarId: avatarId ?? this.avatarId, goals: goals ?? this.goals,
    autonomyLevel: autonomyLevel ?? this.autonomyLevel, streakDays: streakDays ?? this.streakDays,
    lastActive: lastActive ?? this.lastActive, visibilityConfig: visibilityConfig ?? this.visibilityConfig,
    createdAt: createdAt ?? this.createdAt, equippedBodyColor: equippedBodyColor ?? this.equippedBodyColor,
    equippedAccessory: equippedAccessory ?? this.equippedAccessory, equippedEyes: equippedEyes ?? this.equippedEyes,
    lumaPoints: lumaPoints ?? this.lumaPoints, unlockedCosmetics: unlockedCosmetics ?? this.unlockedCosmetics,
    hadNightUsage: hadNightUsage ?? this.hadNightUsage,
  );
}
