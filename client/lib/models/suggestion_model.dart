class SuggestionModel {
  final String id;
  final String sessionId;
  final String groupId;
  final String kalamId;
  final String? kalamTitle;
  final String suggestedById;
  final String? suggestedByName;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime createdAt;

  SuggestionModel({
    required this.id,
    required this.sessionId,
    required this.groupId,
    required this.kalamId,
    this.kalamTitle,
    required this.suggestedById,
    this.suggestedByName,
    required this.status,
    required this.createdAt,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    String kalamId = '';
    String? kalamTitle;
    final rawKalam = json['kalamId'];
    if (rawKalam is Map) {
      kalamId = rawKalam['_id'] ?? rawKalam['id'] ?? '';
      kalamTitle = rawKalam['title'];
    } else {
      kalamId = rawKalam?.toString() ?? '';
    }

    String suggestedById = '';
    String? suggestedByName;
    final rawUser = json['suggestedBy'];
    if (rawUser is Map) {
      suggestedById = rawUser['_id'] ?? rawUser['id'] ?? '';
      suggestedByName = rawUser['name'];
    } else {
      suggestedById = rawUser?.toString() ?? '';
    }

    return SuggestionModel(
      id: json['_id'] ?? json['id'] ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      kalamId: kalamId,
      kalamTitle: kalamTitle,
      suggestedById: suggestedById,
      suggestedByName: suggestedByName,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
