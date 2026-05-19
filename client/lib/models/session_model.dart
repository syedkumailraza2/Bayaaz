import 'kalaam_model.dart';
import 'queue_item_model.dart';

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
  // Legacy flat list, kept for backwards compatibility with old screens.
  // New code should read [queueItems] instead.
  final List<String> queue;
  final List<KalaamModel> queueKalaams;
  final int currentQueueIndex;
  // New source of truth. Carries votes, addedBy, and pin metadata per item.
  final List<SessionQueueItem> queueItems;

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
    this.queueItems = const [],
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    String? kalamId;
    KalaamModel? kalam;
    final raw = json['currentKalamId'];
    if (raw is Map) {
      kalamId = (raw['_id'] ?? raw['id'])?.toString();
      if (raw['content'] != null) {
        kalam = KalaamModel.fromJson(Map<String, dynamic>.from(raw));
      }
    } else if (raw is String) {
      kalamId = raw;
    }

    final rawQueue = (json['queue'] as List?) ?? const [];
    final queueIds = <String>[];
    final queueKalaams = <KalaamModel>[];
    for (final item in rawQueue) {
      if (item is Map) {
        final itemId = (item['_id'] ?? item['id'] ?? '').toString();
        queueIds.add(itemId);
        if (item['content'] != null) {
          queueKalaams.add(KalaamModel.fromJson(Map<String, dynamic>.from(item)));
        }
      } else if (item is String) {
        queueIds.add(item);
      }
    }

    final rawItems = (json['queueItems'] as List?) ?? const [];
    final queueItems = rawItems
        .whereType<Map>()
        .map((m) => SessionQueueItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return SessionModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
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
      queueItems: queueItems,
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
    List<SessionQueueItem>? queueItems,
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
      queueItems: queueItems ?? this.queueItems,
    );
  }

  /// Sorted view of [queueItems] using the same ordering rule the server uses.
  List<SessionQueueItem> get sortedQueue => sortedQueueItems(queueItems);

  bool myVoteOn(String kalaamId, String userId) {
    for (final i in queueItems) {
      if (i.kalaamId == kalaamId) return i.hasVoteFrom(userId);
    }
    return false;
  }
}
