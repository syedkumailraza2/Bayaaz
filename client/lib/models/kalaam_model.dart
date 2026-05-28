class KalaamAuthor {
  final String id;
  final String name;
  final String? avatar;

  KalaamAuthor({required this.id, required this.name, this.avatar});

  factory KalaamAuthor.fromJson(Map<String, dynamic> json) => KalaamAuthor(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        avatar: json['avatar'],
      );
}

class Stanza {
  final int stanzaNumber;
  final List<String> lines;

  Stanza({required this.stanzaNumber, required this.lines});

  factory Stanza.fromJson(Map<String, dynamic> json) => Stanza(
        stanzaNumber: json['stanzaNumber'] ?? 0,
        lines: List<String>.from(json['lines'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'stanzaNumber': stanzaNumber,
        'lines': lines,
      };

  // Preview: first two lines joined
  String get preview => lines.take(2).join('\n');
}

class KalaamModel {
  final String id;
  final String title;
  final List<Stanza> content;
  final String category;
  final bool isPublic;
  final String? poet;
  final KalaamAuthor author;
  final DateTime createdAt;
  final List<String> tags;
  // Engagement counters returned by the server. Older payloads (pre-likes
  // feature) may omit them — we default to 0 / false so the UI never crashes
  // while a cached list is still being read.
  final int likesCount;
  final bool likedByMe;
  final int reads;
  // Per-kalaam aggregate save count (people who've added this to their
  // library) + whether the requesting user is one of them. Computed
  // server-side from User.savedKalaams + the denormalised Kalaam.savesCount
  // mirror, so the detail screen can render a live counter without an
  // extra request.
  final int savesCount;
  final bool savedByMe;
  // Follow-voice reference recitation attached to the kalaam, if any.
  // Synced from the server so a second device can re-download the file
  // instead of being limited to whatever lives in the uploader's app-docs.
  final KalaamReferenceMedia? referenceAudio;

  KalaamModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.isPublic,
    this.poet,
    required this.author,
    required this.createdAt,
    this.tags = const [],
    this.likesCount = 0,
    this.likedByMe = false,
    this.reads = 0,
    this.savesCount = 0,
    this.savedByMe = false,
    this.referenceAudio,
  });

  // Flat preview text for card display (first stanza, first 3 lines)
  String get previewText {
    if (content.isEmpty) return '';
    return content.first.lines.take(3).join('\n');
  }

  KalaamModel copyWith({
    String? id,
    String? title,
    List<Stanza>? content,
    String? category,
    bool? isPublic,
    String? poet,
    KalaamAuthor? author,
    DateTime? createdAt,
    List<String>? tags,
    int? likesCount,
    bool? likedByMe,
    int? reads,
    int? savesCount,
    bool? savedByMe,
    KalaamReferenceMedia? referenceAudio,
    bool clearReferenceAudio = false,
  }) {
    return KalaamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isPublic: isPublic ?? this.isPublic,
      poet: poet ?? this.poet,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      likedByMe: likedByMe ?? this.likedByMe,
      reads: reads ?? this.reads,
      savesCount: savesCount ?? this.savesCount,
      savedByMe: savedByMe ?? this.savedByMe,
      referenceAudio: clearReferenceAudio
          ? null
          : (referenceAudio ?? this.referenceAudio),
    );
  }

  factory KalaamModel.fromJson(Map<String, dynamic> json) => KalaamModel(
        id: json['_id'] ?? json['id'] ?? '',
        title: json['title'] ?? '',
        content: (json['content'] as List? ?? [])
            .map((s) => Stanza.fromJson(s as Map<String, dynamic>))
            .toList(),
        category: json['category'] ?? '',
        isPublic: json['isPublic'] ?? true,
        poet: json['poet'],
        author: KalaamAuthor.fromJson(
          json['author'] is Map ? json['author'] : {'_id': json['author'], 'name': ''},
        ),
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        tags: List<String>.from(json['tags'] ?? []),
        likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
        likedByMe: json['likedByMe'] == true,
        reads: (json['reads'] as num?)?.toInt() ?? 0,
        savesCount: (json['savesCount'] as num?)?.toInt() ?? 0,
        savedByMe: json['savedByMe'] == true,
        referenceAudio: json['referenceAudio'] is Map
            ? KalaamReferenceMedia.fromJson(
                Map<String, dynamic>.from(json['referenceAudio'] as Map),
              )
            : null,
      );
}

/// Server-attached follow-voice reference. Mirrors the `referenceAudio`
/// subdoc on the Kalaam document. Distinct from the Isar
/// `KalaamReferenceMedia` collection (which tracks the *local* cached copy).
class KalaamReferenceMedia {
  final String url;
  final String sourceType;
  final String? sourceUrl;
  final int durationMs;
  final String extension;

  const KalaamReferenceMedia({
    required this.url,
    required this.sourceType,
    this.sourceUrl,
    this.durationMs = 0,
    this.extension = '',
  });

  factory KalaamReferenceMedia.fromJson(Map<String, dynamic> json) =>
      KalaamReferenceMedia(
        url: json['url']?.toString() ?? '',
        sourceType: json['sourceType']?.toString() ?? 'audio_file',
        sourceUrl: json['sourceUrl']?.toString(),
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
        extension: json['extension']?.toString() ?? '',
      );
}

const List<String> kKalaamCategories = ['nauha', 'marsiya', 'qasida', 'qata'];
