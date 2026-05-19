import 'package:isar/isar.dart';

part 'cached_session.g.dart';

/// Last-known session state, persisted whenever we receive a full
/// `session:joined` payload (and on REST refresh). Lets members open the
/// app while offline mid-session and still see something useful.
@collection
class CachedSession {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  late String groupId;
  late String hostId;
  String? currentKalamId;
  late int currentStanza;
  late int currentLine;
  late bool isActive;
  late bool isPlaying;
  late DateTime cachedAt;
}
