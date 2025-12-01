import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'category.g.dart';

@JsonSerializable()
@HiveType(typeId: 9)
class Category extends HiveObject {
  @HiveField(0)
  @JsonKey(name: '_id')
  String? id;

  @HiveField(1)
  @JsonKey(defaultValue: '')
  String name;

  @HiveField(2)
  @JsonKey(defaultValue: '')
  String description;

  @HiveField(3)
  @JsonKey(defaultValue: '#6366f1')
  String color;

  @HiveField(4)
  @JsonKey(defaultValue: 'book')
  String icon;

  @HiveField(5)
  @JsonKey(name: 'userId')
  String? userId;

  @HiveField(6)
  @JsonKey(name: 'isDefault', defaultValue: false)
  bool isDefault;

  @HiveField(7)
  @JsonKey(name: 'isArchived', defaultValue: false)
  bool isArchived;

  @HiveField(8)
  @JsonKey(defaultValue: 0)
  int order;

  @HiveField(9)
  @JsonKey(defaultValue: 0)
  int lyricsCount;

  @HiveField(10)
  DateTime? createdAt;

  @HiveField(11)
  DateTime? updatedAt;

  @HiveField(12)
  bool isSynced;

  @HiveField(13)
  DateTime? lastSyncAt;

  @HiveField(14)
  bool needsSync;

  Category({
    this.id,
    required this.name,
    this.description = '',
    this.color = '#6366f1',
    this.icon = 'book',
    this.userId,
    this.isDefault = false,
    this.isArchived = false,
    this.order = 0,
    this.lyricsCount = 0,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
    this.lastSyncAt,
    this.needsSync = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    String? userId,
    bool? isDefault,
    bool? isArchived,
    int? order,
    int? lyricsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncAt,
    bool? needsSync,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      order: order ?? this.order,
      lyricsCount: lyricsCount ?? this.lyricsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  String get displayName => name.isEmpty ? 'Untitled' : name;
  String get displayDescription => description.isEmpty ? 'No description' : description;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, color: $color, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}