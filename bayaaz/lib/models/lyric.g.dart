// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyric.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LyricAdapter extends TypeAdapter<Lyric> {
  @override
  final int typeId = 5;

  @override
  Lyric read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Lyric(
      id: fields[0] as String?,
      title: fields[1] as String,
      poet: fields[2] as String,
      year: fields[3] as int?,
      content: fields[4] as String,
      plainText: fields[5] as String,
      userId: fields[6] as String?,
      categoryId: fields[7] as String?,
      category: fields[8] as Category?,
      tags: (fields[9] as List).cast<String>(),
      language: fields[10] as String,
      attachments: (fields[11] as List).cast<LyricAttachment>(),
      metadata: fields[12] as LyricMetadata?,
      status: fields[13] as String,
      visibility: fields[14] as String,
      isFavorite: fields[15] as bool,
      isPinned: fields[16] as bool,
      isLocked: fields[17] as bool,
      viewCount: fields[18] as int,
      versions: (fields[19] as List).cast<LyricVersion>(),
      lastViewedAt: fields[20] as DateTime?,
      order: fields[21] as int,
      createdAt: fields[22] as DateTime?,
      updatedAt: fields[23] as DateTime?,
      isSynced: fields[24] as bool,
      lastSyncAt: fields[25] as DateTime?,
      needsSync: fields[26] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Lyric obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.poet)
      ..writeByte(3)
      ..write(obj.year)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.plainText)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.categoryId)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.language)
      ..writeByte(11)
      ..write(obj.attachments)
      ..writeByte(12)
      ..write(obj.metadata)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.visibility)
      ..writeByte(15)
      ..write(obj.isFavorite)
      ..writeByte(16)
      ..write(obj.isPinned)
      ..writeByte(17)
      ..write(obj.isLocked)
      ..writeByte(18)
      ..write(obj.viewCount)
      ..writeByte(19)
      ..write(obj.versions)
      ..writeByte(20)
      ..write(obj.lastViewedAt)
      ..writeByte(21)
      ..write(obj.order)
      ..writeByte(22)
      ..write(obj.createdAt)
      ..writeByte(23)
      ..write(obj.updatedAt)
      ..writeByte(24)
      ..write(obj.isSynced)
      ..writeByte(25)
      ..write(obj.lastSyncAt)
      ..writeByte(26)
      ..write(obj.needsSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LyricAttachmentAdapter extends TypeAdapter<LyricAttachment> {
  @override
  final int typeId = 6;

  @override
  LyricAttachment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricAttachment(
      type: fields[0] as String,
      url: fields[1] as String,
      publicId: fields[2] as String,
      fileName: fields[3] as String,
      fileSize: fields[4] as int,
      mimeType: fields[5] as String,
      uploadedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LyricAttachment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.publicId)
      ..writeByte(3)
      ..write(obj.fileName)
      ..writeByte(4)
      ..write(obj.fileSize)
      ..writeByte(5)
      ..write(obj.mimeType)
      ..writeByte(6)
      ..write(obj.uploadedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricAttachmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LyricMetadataAdapter extends TypeAdapter<LyricMetadata> {
  @override
  final int typeId = 7;

  @override
  LyricMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricMetadata(
      source: fields[0] as String,
      reference: fields[1] as String,
      notes: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LyricMetadata obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.source)
      ..writeByte(1)
      ..write(obj.reference)
      ..writeByte(2)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LyricVersionAdapter extends TypeAdapter<LyricVersion> {
  @override
  final int typeId = 8;

  @override
  LyricVersion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricVersion(
      content: fields[0] as String,
      modifiedAt: fields[1] as DateTime?,
      reason: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LyricVersion obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.modifiedAt)
      ..writeByte(2)
      ..write(obj.reason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricVersionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lyric _$LyricFromJson(Map<String, dynamic> json) => Lyric(
      id: json['_id'] as String?,
      title: json['title'] as String? ?? '',
      poet: json['poet'] as String? ?? '',
      year: (json['year'] as num?)?.toInt(),
      content: json['content'] as String? ?? '',
      plainText: json['plainText'] as String? ?? '',
      userId: json['userId'] as String?,
      categoryId: json['categoryId'] as String?,
      category: json['category'] == null
          ? null
          : Category.fromJson(json['category'] as Map<String, dynamic>),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      language: json['language'] as String? ?? 'urdu',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => LyricAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] == null
          ? null
          : LyricMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      status: json['status'] as String? ?? 'published',
      visibility: json['visibility'] as String? ?? 'private',
      isFavorite: json['isFavorite'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      versions: (json['versions'] as List<dynamic>?)
              ?.map((e) => LyricVersion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastViewedAt: json['lastViewedAt'] == null
          ? null
          : DateTime.parse(json['lastViewedAt'] as String),
      order: (json['order'] as num?)?.toInt() ?? 0,
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

Map<String, dynamic> _$LyricToJson(Lyric instance) => <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'poet': instance.poet,
      'year': instance.year,
      'content': instance.content,
      'plainText': instance.plainText,
      'userId': instance.userId,
      'categoryId': instance.categoryId,
      'category': instance.category,
      'tags': instance.tags,
      'language': instance.language,
      'attachments': instance.attachments,
      'metadata': instance.metadata,
      'status': instance.status,
      'visibility': instance.visibility,
      'isFavorite': instance.isFavorite,
      'isPinned': instance.isPinned,
      'isLocked': instance.isLocked,
      'viewCount': instance.viewCount,
      'versions': instance.versions,
      'lastViewedAt': instance.lastViewedAt?.toIso8601String(),
      'order': instance.order,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isSynced': instance.isSynced,
      'lastSyncAt': instance.lastSyncAt?.toIso8601String(),
      'needsSync': instance.needsSync,
    };

LyricAttachment _$LyricAttachmentFromJson(Map<String, dynamic> json) =>
    LyricAttachment(
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
      publicId: json['publicId'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      mimeType: json['mimeType'] as String? ?? '',
      uploadedAt: json['uploadedAt'] == null
          ? null
          : DateTime.parse(json['uploadedAt'] as String),
    );

Map<String, dynamic> _$LyricAttachmentToJson(LyricAttachment instance) =>
    <String, dynamic>{
      'type': instance.type,
      'url': instance.url,
      'publicId': instance.publicId,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
      'uploadedAt': instance.uploadedAt?.toIso8601String(),
    };

LyricMetadata _$LyricMetadataFromJson(Map<String, dynamic> json) =>
    LyricMetadata(
      source: json['source'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );

Map<String, dynamic> _$LyricMetadataToJson(LyricMetadata instance) =>
    <String, dynamic>{
      'source': instance.source,
      'reference': instance.reference,
      'notes': instance.notes,
    };

LyricVersion _$LyricVersionFromJson(Map<String, dynamic> json) => LyricVersion(
      content: json['content'] as String? ?? '',
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      reason: json['reason'] as String? ?? '',
    );

Map<String, dynamic> _$LyricVersionToJson(LyricVersion instance) =>
    <String, dynamic>{
      'content': instance.content,
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'reason': instance.reason,
    };
