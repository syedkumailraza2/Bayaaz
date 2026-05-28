import 'package:isar/isar.dart';

part 'kalaam_reference_audio.g.dart';

@collection
class KalaamReferenceAudio {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String kalaamId;

  late String localWavPath;

  /// 'audio_file' | 'video_file' | 'youtube'
  late String sourceType;

  String? sourceUrl;

  late int durationMs;

  late DateTime createdAt;

  /// true once Vosk has processed the WAV into KalaamLineMetadata rows
  late bool metadataGenerated;
}
