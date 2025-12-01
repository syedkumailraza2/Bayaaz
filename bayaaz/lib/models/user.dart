import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'user.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  @JsonKey(name: '_id')
  String? id;

  @HiveField(1)
  @JsonKey(defaultValue: '')
  String username;

  @HiveField(2)
  @JsonKey(defaultValue: '')
  String email;

  @HiveField(3)
  UserProfile? profile;

  @HiveField(4)
  UserPreferences? preferences;

  @HiveField(5)
  UserStats? stats;

  @HiveField(6)
  UserSubscription? subscription;

  @HiveField(7)
  DateTime? createdAt;

  @HiveField(8)
  DateTime? updatedAt;

  User({
    this.id,
    required this.username,
    required this.email,
    this.profile,
    this.preferences,
    this.stats,
    this.subscription,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? username,
    String? email,
    UserProfile? profile,
    UserPreferences? preferences,
    UserStats? stats,
    UserSubscription? subscription,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profile: profile ?? this.profile,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      subscription: subscription ?? this.subscription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email)';
  }
}

@JsonSerializable()
@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  @JsonKey(defaultValue: '')
  String firstName;

  @HiveField(1)
  @JsonKey(defaultValue: '')
  String lastName;

  @HiveField(2)
  @JsonKey(defaultValue: '')
  String avatar;

  @HiveField(3)
  @JsonKey(defaultValue: '')
  String bio;

  UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.avatar = '',
    this.bio = '',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  String get fullName => '$firstName $lastName'.trim();

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? avatar,
    String? bio,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
    );
  }
}

@JsonSerializable()
@HiveType(typeId: 2)
class UserPreferences extends HiveObject {
  @HiveField(0)
  @JsonKey(defaultValue: 'light')
  String theme;

  @HiveField(1)
  @JsonKey(defaultValue: 16)
  int fontSize;

  @HiveField(2)
  @JsonKey(defaultValue: true)
  bool autoSync;

  @HiveField(3)
  @JsonKey(defaultValue: true)
  bool notifications;

  UserPreferences({
    this.theme = 'light',
    this.fontSize = 16,
    this.autoSync = true,
    this.notifications = true,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) => _$UserPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);

  UserPreferences copyWith({
    String? theme,
    int? fontSize,
    bool? autoSync,
    bool? notifications,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      autoSync: autoSync ?? this.autoSync,
      notifications: notifications ?? this.notifications,
    );
  }
}

@JsonSerializable()
@HiveType(typeId: 3)
class UserStats extends HiveObject {
  @HiveField(0)
  @JsonKey(defaultValue: 0)
  int totalLyrics;

  @HiveField(1)
  @JsonKey(defaultValue: 0)
  int totalCategories;

  @HiveField(2)
  @JsonKey(defaultValue: 0)
  int storageUsed;

  @HiveField(3)
  DateTime? lastLogin;

  UserStats({
    this.totalLyrics = 0,
    this.totalCategories = 0,
    this.storageUsed = 0,
    this.lastLogin,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => _$UserStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsToJson(this);

  UserStats copyWith({
    int? totalLyrics,
    int? totalCategories,
    int? storageUsed,
    DateTime? lastLogin,
  }) {
    return UserStats(
      totalLyrics: totalLyrics ?? this.totalLyrics,
      totalCategories: totalCategories ?? this.totalCategories,
      storageUsed: storageUsed ?? this.storageUsed,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

@JsonSerializable()
@HiveType(typeId: 4)
class UserSubscription extends HiveObject {
  @HiveField(0)
  @JsonKey(defaultValue: 'free')
  String type;

  @HiveField(1)
  DateTime? startDate;

  @HiveField(2)
  DateTime? endDate;

  UserSubscription({
    this.type = 'free',
    this.startDate,
    this.endDate,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) => _$UserSubscriptionFromJson(json);
  Map<String, dynamic> toJson() => _$UserSubscriptionToJson(this);

  bool get isPremium => type == 'premium';

  bool get isActive {
    if (type == 'free') return true;
    if (startDate == null || endDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(startDate!) && now.isBefore(endDate!);
  }

  UserSubscription copyWith({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return UserSubscription(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}