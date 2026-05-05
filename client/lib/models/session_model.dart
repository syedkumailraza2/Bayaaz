import 'kalaam_model.dart';

class SessionModel {
  final String id;
  final String groupId;
  final String hostId;
  final String? currentKalamId;
  final KalaamModel? currentKalam;
  final int currentStanza;
  final int currentLine;
  final bool isActive;
  final bool isPlaying;
  final List<String> queue;
  final List<KalaamModel> queueKalaams;
  final int currentQueueIndex;

  SessionModel({
    required this.id,
    required this.groupId,
    required this.hostId,
    this.currentKalamId,
    this.currentKalam,
    required this.currentStanza,
    required this.currentLine,
    required this.isActive,
    required this.isPlaying,
    required this.queue,
    required this.queueKalaams,
    required this.currentQueueIndex,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    String? kalamId;
    KalaamModel? kalam;
    final raw = json['currentKalamId'];
    if (raw is Map) {
      kalamId = raw['_id'] ?? raw['id'];
      if (raw['content'] != null) {
        kalam = KalaamModel.fromJson(raw as Map<String, dynamic>);
      }
    } else if (raw is String) {
      kalamId = raw;
    }

    final rawQueue = json['queue'] as List? ?? [];
    final queueIds = <String>[];
    final queueKalaams = <KalaamModel>[];
    for (final item in rawQueue) {
      if (item is Map) {
        final itemId = item['_id'] ?? item['id'] ?? '';
        queueIds.add(itemId as String);
        if (item['content'] != null) {
          queueKalaams.add(KalaamModel.fromJson(item as Map<String, dynamic>));
        }
      } else if (item is String) {
        queueIds.add(item);
      }
    }

    return SessionModel(
      id: json['_id'] ?? json['id'] ?? '',
      groupId: json['groupId']?.toString() ?? '',
      hostId: json['hostId']?.toString() ?? '',
      currentKalamId: kalamId,
      currentKalam: kalam,
      currentStanza: json['currentStanza'] ?? 0,
      currentLine: json['currentLine'] ?? 0,
      isActive: json['isActive'] ?? true,
      isPlaying: json['isPlaying'] ?? false,
      queue: queueIds,
      queueKalaams: queueKalaams,
      currentQueueIndex: json['currentQueueIndex'] ?? 0,
    );
  }

  SessionModel copyWith({
    String? id,
    String? groupId,
    String? hostId,
    String? currentKalamId,
    KalaamModel? currentKalam,
    int? currentStanza,
    int? currentLine,
    bool? isActive,
    bool? isPlaying,
    List<String>? queue,
    List<KalaamModel>? queueKalaams,
    int? currentQueueIndex,
  }) {
    return SessionModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      hostId: hostId ?? this.hostId,
      currentKalamId: currentKalamId ?? this.currentKalamId,
      currentKalam: currentKalam ?? this.currentKalam,
      currentStanza: currentStanza ?? this.currentStanza,
      currentLine: currentLine ?? this.currentLine,
      isActive: isActive ?? this.isActive,
      isPlaying: isPlaying ?? this.isPlaying,
      queue: queue ?? this.queue,
      queueKalaams: queueKalaams ?? this.queueKalaams,
      currentQueueIndex: currentQueueIndex ?? this.currentQueueIndex,
    );
  }
}
