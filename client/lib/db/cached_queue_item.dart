import 'package:isar/isar.dart';

part 'cached_queue_item.g.dart';

/// Mirror of a single SessionQueueItem from the server. Indexed by
/// (sessionId, kalaamId) so member adds/votes can find their row again
/// after a reconnect.
@collection
class CachedQueueItem {
  Id id = Isar.autoIncrement;

  @Index()
  late String sessionId;

  @Index()
  late String kalaamId;

  String? kalaamTitle;
  String? kalaamCategory;
  String? kalaamAuthorName;

  late String addedById;
  late DateTime addedAt;

  /// IDs of users who voted for this item. Stored as a flat list because
  /// Isar v3 doesn't support `Set<String>`.
  late List<String> voters;

  late bool pinned;
  int? pinPosition;

  /// True for rows created by an offline add that hasn't synced yet. The
  /// drain clears it once the server confirms.
  late bool pendingSync;

  late DateTime cachedAt;
}
