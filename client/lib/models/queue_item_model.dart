import 'kalaam_model.dart';

/// One entry in a session's queue. Vote counting is just `votes.length`.
///
/// The list is comparable by (pinned/pinPosition, voteCount desc, addedAt asc),
/// matching the server-side `sortedQueueItems` algorithm.
class SessionQueueItem {
  final String kalaamId;
  final String? kalaamTitle;
  final String? kalaamCategory;
  final String? kalaamAuthorName;
  final String addedById;
  final DateTime addedAt;
  final Set<String> votes;
  final bool pinned;
  final int? pinPosition;

  /// Set to true on items the user just created offline. The provider clears
  /// this when the server confirms (or just removes the temp row in favor of
  /// the server's enriched version).
  final bool pendingSync;

  SessionQueueItem({
    required this.kalaamId,
    this.kalaamTitle,
    this.kalaamCategory,
    this.kalaamAuthorName,
    required this.addedById,
    required this.addedAt,
    Set<String>? votes,
    this.pinned = false,
    this.pinPosition,
    this.pendingSync = false,
  }) : votes = votes ?? <String>{};

  int get voteCount => votes.length;

  bool hasVoteFrom(String userId) => votes.contains(userId);

  factory SessionQueueItem.fromJson(Map<String, dynamic> json) {
    String? kalaamId;
    String? title;
    String? category;
    String? authorName;
    final rawKalaam = json['kalaamId'];
    if (rawKalaam is Map) {
      kalaamId = (rawKalaam['_id'] ?? rawKalaam['id'])?.toString();
      title = rawKalaam['title'] as String?;
      category = rawKalaam['category'] as String?;
      final rawAuthor = rawKalaam['author'];
      if (rawAuthor is Map) {
        authorName = rawAuthor['name'] as String?;
      }
    } else if (rawKalaam is String) {
      kalaamId = rawKalaam;
    }

    final rawVotes = (json['votes'] as List?) ?? const [];
    final votes = rawVotes.map((v) {
      if (v is Map) return (v['_id'] ?? v['id']).toString();
      return v.toString();
    }).toSet();

    return SessionQueueItem(
      kalaamId: kalaamId ?? '',
      kalaamTitle: title,
      kalaamCategory: category,
      kalaamAuthorName: authorName,
      addedById: (json['addedBy'] is Map
              ? (json['addedBy']['_id'] ?? json['addedBy']['id'])
              : json['addedBy'])
          ?.toString() ??
          '',
      addedAt: DateTime.tryParse(json['addedAt']?.toString() ?? '') ?? DateTime.now(),
      votes: votes,
      pinned: (json['pinned'] as bool?) ?? false,
      pinPosition: json['pinPosition'] is int ? json['pinPosition'] as int : null,
    );
  }

  /// Build an optimistic item from a freshly-picked kalaam (offline add).
  factory SessionQueueItem.optimistic({
    required KalaamModel kalaam,
    required String addedById,
  }) {
    return SessionQueueItem(
      kalaamId: kalaam.id,
      kalaamTitle: kalaam.title,
      kalaamCategory: kalaam.category,
      kalaamAuthorName: kalaam.author.name,
      addedById: addedById,
      addedAt: DateTime.now(),
      votes: <String>{},
      pendingSync: true,
    );
  }

  SessionQueueItem copyWith({
    Set<String>? votes,
    bool? pinned,
    int? pinPosition,
    bool? pendingSync,
    bool clearPinPosition = false,
  }) {
    return SessionQueueItem(
      kalaamId: kalaamId,
      kalaamTitle: kalaamTitle,
      kalaamCategory: kalaamCategory,
      kalaamAuthorName: kalaamAuthorName,
      addedById: addedById,
      addedAt: addedAt,
      votes: votes ?? this.votes,
      pinned: pinned ?? this.pinned,
      pinPosition: clearPinPosition ? null : (pinPosition ?? this.pinPosition),
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}

/// Sort items the same way the server does so the UI matches the broadcast
/// state during the brief window before a refresh lands.
List<SessionQueueItem> sortedQueueItems(Iterable<SessionQueueItem> items) {
  final pinned = items.where((i) => i.pinned).toList()
    ..sort((a, b) {
      final pa = a.pinPosition ?? 1 << 30;
      final pb = b.pinPosition ?? 1 << 30;
      if (pa != pb) return pa.compareTo(pb);
      return a.addedAt.compareTo(b.addedAt);
    });
  final unpinned = items.where((i) => !i.pinned).toList()
    ..sort((a, b) {
      final cmp = b.voteCount.compareTo(a.voteCount);
      if (cmp != 0) return cmp;
      return a.addedAt.compareTo(b.addedAt);
    });
  return [...pinned, ...unpinned];
}
