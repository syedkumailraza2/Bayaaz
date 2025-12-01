// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 9;

  @override
  Category read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Category(
      id: fields[0] as String?,
      name: fields[1] as String,
      description: fields[2] as String,
      color: fields[3] as String,
      icon: fields[4] as String,
      userId: fields[5] as String?,
      isDefault: fields[6] as bool,
      isArchived: fields[7] as bool,
      order: fields[8] as int,
      lyricsCount: fields[9] as int,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      isSynced: fields[12] as bool,
      lastSyncAt: fields[13] as DateTime?,
      needsSync: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.icon)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.isDefault)
      ..writeByte(7)
      ..write(obj.isArchived)
      ..writeByte(8)
      ..write(obj.order)
      ..writeByte(9)
      ..write(obj.lyricsCount)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.isSynced)
      ..writeByte(13)
      ..write(obj.lastSyncAt)
      ..writeByte(14)
      ..write(obj.needsSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      color: json['color'] as String? ?? '#6366f1',
      icon: json['icon'] as String? ?? 'book',
      userId: json['userId'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      order: (json['order'] as num?)?.toInt() ?? 0,
      lyricsCount: (json['lyricsCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      lastSyncAt: json['lastSyncAt'] == null
          ? null
          : DateTime.parse(json['lastSyncAt'] as String),
      needsSync: json['needsSync'] as bool? ?? true,
    );

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'color': instance.color,
      'icon': instance.icon,
      'userId': instance.userId,
      'isDefault': instance.isDefault,
      'isArchived': instance.isArchived,
      'order': instance.order,
      'lyricsCount': instance.lyricsCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isSynced': instance.isSynced,
      'lastSyncAt': instance.lastSyncAt?.toIso8601String(),
      'needsSync': instance.needsSync,
    };
