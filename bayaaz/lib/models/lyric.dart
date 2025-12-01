import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'category.dart';

part 'lyric.g.dart';

@JsonSerializable()
@HiveType(typeId: 5)
class Lyric extends HiveObject {
  @HiveField(0)
  @JsonKey(name: '_id')
  String? id;

  @HiveField(1)
  @JsonKey(defaultValue: '')
  String title;

  @HiveField(2)
  @JsonKey(defaultValue: '')
  String poet;

  @HiveField(3)
  int? year;

  @HiveField(4)
  @JsonKey(defaultValue: '')
  String content;

  @HiveField(5)
  @JsonKey(defaultValue: '')
  String plainText;

  @HiveField(6)
  @JsonKey(name: 'userId')
  String? userId;

  @HiveField(7)
  @JsonKey(name: 'categoryId')
  String? categoryId;

  @HiveField(8)
  Category? category;

  @HiveField(9)
  @JsonKey(defaultValue: [])
  List<String> tags;

  @HiveField(10)
  @JsonKey(defaultValue: 'urdu')
  String language;

  @HiveField(11)
  @JsonKey(defaultValue: [])
  List<LyricAttachment> attachments;

  @HiveField(12)
  LyricMetadata? metadata;

  @HiveField(13)
  @JsonKey(defaultValue: 'published')
  String status;

  @HiveField(14)
  @JsonKey(defaultValue: 'private')
  String visibility;

  @HiveField(15)
  @JsonKey(defaultValue: false)
  bool isFavorite;

  @HiveField(16)
  @JsonKey(defaultValue: false)
  bool isPinned;

  @HiveField(17)
  @JsonKey(defaultValue: false)
  bool isLocked;

  @HiveField(18)
  @JsonKey(defaultValue: 0)
  int viewCount;

  @HiveField(19)
  @JsonKey(defaultValue: [])
  List<LyricVersion> versions;

  @HiveField(20)
  DateTime? lastViewedAt;

  @HiveField(21)
  @JsonKey(defaultValue: 0)
  int order;

  @HiveField(22)
  DateTime? createdAt;

  @HiveField(23)
  DateTime? updatedAt;

  @HiveField(24)
  bool isSynced;

  @HiveField(25)
  DateTime? lastSyncAt;

  @HiveField(26)
  bool needsSync;

  Lyric({
    this.id,
    required this.title,
    this.poet = '',
    this.year,
    required this.content,
    this.plainText = '',
    this.userId,
    this.categoryId,
    this.category,
    this.tags = const [],
    this.language = 'urdu',
    this.attachments = const [],
    this.metadata,
    this.status = 'published',
    this.visibility = 'private',
    this.isFavorite = false,
    this.isPinned = false,
    this.isLocked = false,
    this.viewCount = 0,
    this.versions = const [],
    this.lastViewedAt,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
    this.lastSyncAt,
    this.needsSync = true,
  });

  factory Lyric.fromJson(Map<String, dynamic> json) => _$LyricFromJson(json);
  Map<String, dynamic> toJson() => _$LyricToJson(this);

  Lyric copyWith({
    String? id,
    String? title,
    String? poet,
    int? year,
    String? content,
    String? plainText,
    String? userId,
    String? categoryId,
    Category? category,
    List<String>? tags,
    String? language,
    List<LyricAttachment>? attachments,
    LyricMetadata? metadata,
    String? status,
    String? visibility,
    bool? isFavorite,
    bool? isPinned,
    bool? isLocked,
    int? viewCount,
    List<LyricVersion>? versions,
    DateTime? lastViewedAt,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncAt,
    bool? needsSync,
  }) {
    return Lyric(
      id: id ?? this.id,
      title: title ?? this.title,
      poet: poet ?? this.poet,
      year: year ?? this.year,
      content: content ?? this.content,
      plainText: plainText ?? this.plainText,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      language: language ?? this.language,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      viewCount: viewCount ?? this.viewCount,
      versions: versions ?? this.versions,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  String get displayTitle => title.isEmpty ? 'Untitled' : title;
  String get displayPoet => poet.isEmpty ? 'Unknown' : poet;
  String get categoryName => category?.name ?? 'Uncategorized';

  @override
  String toString() {
    return 'Lyric(id: $id, title: $title, poet: $poet)';
  }
}

@JsonSerializable()
@HiveType(typeId: 6)
class LyricAttachment extends HiveObject {
  @HiveField(0)
  @JsonKey(defaultValue: '')
  String type;

  @HiveField(1)
  @JsonKey(defaultValue: '')
  String url;

  @HiveField(2)
  @JsonKey(name: 'publicId', defaultValue: '')
  String publicId;

  @HiveField(3)
  @JsonKey(name: 'fileName', defaultValue: '')
  String fileName;

  @HiveField(4)
  @JsonKey(name: 'fileSize', defaultValue: 0)
  int fileSize;

  @HiveField(5)
  @JsonKey(name: 'mimeType', defaultValue: '')
  String mimeType;

  @HiveField(6)
  DateTime? uploadedAt;

  LyricAttachment({
    this.type = '',
    this.url = '',
    this.publicId = '',
    this.fileName = '',
    this.fileSize = 0,
    this.mimeType = '',
    this.uploadedAt,
  });

  factory LyricAttachment.fromJson(Map<String, dynamic> json) => _$LyricAttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$LyricAttachmentToJson(this);

  String get fileSizeDisplay {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool get isImage => type == 'image';
  bool get isAudio => type == 'audio';
  bool get isDocument => type == 'document';
}

@JsonSerializable()
@HiveType(typeId: 7)
class LyricMetadata extends HiveObject {
  @HiveField(0)
  @JsonKey(defaultValue: '')
  String source;

  @HiveField(1)
  @JsonKey(defaultValue: '')
  String reference;

  @HiveField(2)
  @JsonKey(defaultValue: '')
  String notes;

  LyricMetadata({
    this.source = '',
    this.reference = '',
    this.notes = '',
  });

  factory LyricMetadata.fromJson(Map<String, dynamic> json) => _$LyricMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$LyricMetadataToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 8)
class LyricVersion extends HiveObject {
  @HiveField(0)
  @JsonKey(defaultValue: '')
  String content;

  @HiveField(1)
  @JsonKey(name: 'modifiedAt')
  DateTime? modifiedAt;

  @HiveField(2)
  @JsonKey(defaultValue: '')
  String reason;

  LyricVersion({
    this.content = '',
    this.modifiedAt,
    this.reason = '',
  });

  factory LyricVersion.fromJson(Map<String, dynamic> json) => _$LyricVersionFromJson(json);
  Map<String, dynamic> toJson() => _$LyricVersionToJson(this);

  String get displayDate {
    if (modifiedAt == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(modifiedAt!);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}