import 'package:isar/isar.dart';

part 'cached_queue_snapshot.g.dart';

/// Cache of the group's end-of-session snapshots so the "past queues"
/// panel renders instantly offline.
@collection
class CachedQueueSnapshot {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  @Index()
  late String groupId;

  late DateTime snapshotCreatedAt;

  /// Kalaam IDs in the snapshot's stored order.
  late List<String> kalaamIds;

  /// Cached titles parallel to [kalaamIds] for offline display. May be empty
  /// if we haven't loaded the populated snapshot yet.
  late List<String> kalaamTitles;

  late DateTime cachedAt;
}
