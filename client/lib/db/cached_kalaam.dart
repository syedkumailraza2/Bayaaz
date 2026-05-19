import 'package:isar/isar.dart';

part 'cached_kalaam.g.dart';

@collection
class CachedKalaam {
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

  @Index()
  late int feedPosition;

  late DateTime cachedAt;
}

@embedded
class CachedStanza {
  int stanzaNumber = 0;
  List<String> lines = const [];
}
