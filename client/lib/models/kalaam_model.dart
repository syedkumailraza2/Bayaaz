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
  });

  // Flat preview text for card display (first stanza, first 3 lines)
  String get previewText {
    if (content.isEmpty) return '';
    return content.first.lines.take(3).join('\n');
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
      );
}

const List<String> kKalaamCategories = ['nauha', 'marsiya', 'qasida', 'qata'];
