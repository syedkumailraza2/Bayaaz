import 'package:isar/isar.dart';

part 'practice_session_record.g.dart';

@collection
class PracticeSessionRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late String kalaamId;

  late String kalaamTitle;
  late String mode;

  @Index()
  late DateTime sessionAt;

  late double overallScore;
  late double accuracyScore;
  late double completionScore;
  late double flowScore;
  late double pauseScore;

  // JSON-encoded List<double> of per-line accuracy values.
  late String perLineScoresJson;

  // Idempotency token minted at write-time. Sent on the upload retry so the
  // server can dedupe replays from the offline drain queue.
  @Index(unique: true, replace: false)
  String clientToken = '';

  // True once the server confirmed the write. Rows with false are drained
  // by OfflineSyncService.drainPendingPracticeSessions on reconnect.
  @Index()
  bool syncedToServer = false;
}
