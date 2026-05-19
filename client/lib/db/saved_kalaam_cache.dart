import 'package:isar/isar.dart';
import 'cached_kalaam.dart';

part 'saved_kalaam_cache.g.dart';

@collection
class SavedKalaamCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  late String title;
  late List<CachedStanza> content;
  late String category;
  late bool isPublic;
  String? poet;

  late String authorId;
  late String authorName;
  String? authorAvatar;

  @Index()
  late DateTime createdAt;

  late List<String> tags;

  late DateTime cachedAt;

  late bool pendingSync;
}
