import 'package:isar/isar.dart';

part 'kalaam_line_metadata.g.dart';

@collection
class KalaamLineMetadata {
  Id id = Isar.autoIncrement;

  @Index()
  late String kalaamId;

  /// Flat line index across all stanzas (0-based)
  late int lineIndex;

  late String lineText;

  late double startSec;

  late double endSec;

  /// Silence duration between end of this line and start of the next
  late double pauseAfterSec;

  late double speakingRateWpm;
}
