import 'package:isar/isar.dart';

part 'kalaam_practice_meta.g.dart';

@collection
class KalaamPracticeMeta {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String kalaamId;

  late int totalSessions;
  late double bestOverallScore;
  late DateTime lastPracticedAt;
  late int currentStreak;
  late int longestStreak;

  // Comma-separated flat line indices that score poorly on average.
  late String weakLineIndices;
}
