import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/kalaam_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/session_model.dart';
import '../models/suggestion_model.dart';

// Resolved from AppConfig (runtime override > --dart-define=BASE_URL > default).
// Use the in-app Server URL dialog to change this without rebuilding.
String get kBaseUrl => AppConfig.apiUrl;

class ApiService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth
  static Map<String, dynamic> _parseBody(http.Response res) {
    if (res.body.isEmpty) return {};
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      if (res.statusCode == 201) return jsonDecode(res.body);
      throw Exception(_parseBody(res)['message'] ?? 'Registration failed (${res.statusCode})');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Cannot reach server. Is it running?');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception(_parseBody(res)['message'] ?? 'Login failed (${res.statusCode})');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Cannot reach server. Is it running?');
    }
  }

  // Kalaams — paginated search/filter feed
  static Future<KalaamPage> getPublicKalaams({
    String? category,
    String? q,
    String? tag,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (category != null && category.isNotEmpty) 'category': category,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (tag != null && tag.isNotEmpty) 'tag': tag,
    };
    final uri = Uri.parse('$kBaseUrl/kalaams').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _authHeaders());
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      // Tolerate the legacy array shape so old servers still work
      if (body is List) {
        final items = body.map((j) => KalaamModel.fromJson(j)).toList();
        return KalaamPage(items: items, page: 1, limit: items.length, total: items.length, hasMore: false);
      }
      return KalaamPage.fromJson(body as Map<String, dynamic>);
    }
    throw Exception('Failed to load kalaams');
  }

  static Future<List<KalaamModel>> getMyKalaams() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/kalaams/mine'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => KalaamModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load your kalaams');
  }

  static Future<KalaamModel> createKalaam({
    required String title,
    required List<Map<String, dynamic>> content,
    required String category,
    required bool isPublic,
    String? poet,
    List<String> tags = const [],
  }) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/kalaams'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'title': title,
        'content': content,
        'category': category,
        'isPublic': isPublic,
        if (poet != null && poet.isNotEmpty) 'poet': poet,
        'tags': tags,
      }),
    );
    if (res.statusCode == 201) return KalaamModel.fromJson(jsonDecode(res.body));
    throw Exception(jsonDecode(res.body)['message'] ?? 'Failed to create kalaam');
  }

  static Future<KalaamModel> updateKalaam({
    required String id,
    required String title,
    required List<Map<String, dynamic>> content,
    required String category,
    required bool isPublic,
    String? poet,
    List<String> tags = const [],
  }) async {
    final res = await http.put(
      Uri.parse('$kBaseUrl/kalaams/$id'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'title': title,
        'content': content,
        'category': category,
        'isPublic': isPublic,
        if (poet != null && poet.isNotEmpty) 'poet': poet,
        'tags': tags,
      }),
    );
    if (res.statusCode == 200) return KalaamModel.fromJson(jsonDecode(res.body));
    throw Exception(_parseBody(res)['message'] ?? 'Failed to update kalaam');
  }

  static Future<Map<String, dynamic>> toggleSave(String id) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/kalaams/$id/save'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to save kalaam');
  }

  /// Toggles the current user's like on a kalaam. Returns
  /// `{ liked: bool, likesCount: int }`.
  static Future<Map<String, dynamic>> toggleLike(String id) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/kalaams/$id/like'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(_parseBody(res)['message'] ?? 'Failed to like kalaam');
  }

  /// Increments the read counter for a kalaam. Fire-and-forget — caller
  /// should not block on the result. Returns `{ reads: int }` on success.
  static Future<Map<String, dynamic>> recordView(String id) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/kalaams/$id/view'),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to record view');
  }

  /// Patches the signed-in user's profile. Pass `avatar: null` (with
  /// `clearAvatar: true`) to remove the avatar.
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? avatar,
    bool clearAvatar = false,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (clearAvatar) {
      body['avatar'] = null;
    } else if (avatar != null) {
      body['avatar'] = avatar;
    }
    final res = await http.patch(
      Uri.parse('$kBaseUrl/auth/me'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(_parseBody(res)['message'] ?? 'Failed to update profile');
  }

  static Future<List<KalaamModel>> getSavedKalaams() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/kalaams/saved'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => KalaamModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load saved kalaams');
  }

  static Future<KalaamModel> toggleVisibility(String id) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl/kalaams/$id/visibility'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return KalaamModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to update visibility');
  }

  static Future<void> deleteKalaam(String id) async {
    final res = await http.delete(
      Uri.parse('$kBaseUrl/kalaams/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to delete kalaam');
    }
  }

  static Future<UserModel> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) return UserModel.fromJson(jsonDecode(userJson));
    throw Exception('Not logged in');
  }

  // ─── Groups ───────────────────────────────────────────────────────────────

  static Future<List<GroupModel>> getGroups() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/groups'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => GroupModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load groups');
  }

  static Future<GroupModel> createGroup(String name) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/groups'),
      headers: await _authHeaders(),
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode == 201) return GroupModel.fromJson(jsonDecode(res.body));
    throw Exception(_parseBody(res)['message'] ?? 'Failed to create group');
  }

  static Future<GroupModel> getGroup(String id) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/groups/$id'),
      headers: await _authHeaders(),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) return GroupModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to load group (${res.statusCode})');
  }

  static Future<GroupModel> addMember(String groupId, String userId) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/groups/$groupId/members'),
      headers: await _authHeaders(),
      body: jsonEncode({'userId': userId}),
    );
    if (res.statusCode == 200) return GroupModel.fromJson(jsonDecode(res.body));
    throw Exception(_parseBody(res)['message'] ?? 'Failed to add member');
  }

  static Future<GroupModel> removeMember(String groupId, String uid) async {
    final res = await http.delete(
      Uri.parse('$kBaseUrl/groups/$groupId/members/$uid'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return GroupModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to remove member');
  }

  // ─── Sessions ─────────────────────────────────────────────────────────────

  static Future<SessionModel> startSession(
    String groupId, {
    String? loadFromSnapshotId,
    List<String>? kalaamIds,
  }) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/groups/$groupId/sessions'),
      headers: await _authHeaders(),
      body: jsonEncode({
        if (loadFromSnapshotId != null) 'loadFromSnapshotId': loadFromSnapshotId,
        if (kalaamIds != null && kalaamIds.isNotEmpty) 'kalaamIds': kalaamIds,
      }),
    );
    if (res.statusCode == 201) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception(_parseBody(res)['message'] ?? 'Failed to start session');
  }

  static Future<SessionModel?> getActiveSession(String groupId) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/groups/$groupId/sessions/active'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    if (res.statusCode == 404) return null;
    throw Exception('Failed to load active session');
  }

  static Future<SessionModel> getSession(String id) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/sessions/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to load session');
  }

  static Future<SessionModel> setKalam(String sessionId, String kalamId) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl/sessions/$sessionId/kalam'),
      headers: await _authHeaders(),
      body: jsonEncode({'kalamId': kalamId}),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to set kalam');
  }

  static Future<SessionModel> setStanza(String sessionId, int stanza, int line) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl/sessions/$sessionId/stanza'),
      headers: await _authHeaders(),
      body: jsonEncode({'stanza': stanza, 'line': line}),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to set stanza');
  }

  static Future<SessionModel> setPlayState(String sessionId, bool isPlaying) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl/sessions/$sessionId/playstate'),
      headers: await _authHeaders(),
      body: jsonEncode({'isPlaying': isPlaying}),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to set play state');
  }

  static Future<void> endSession(String sessionId) async {
    final res = await http.delete(
      Uri.parse('$kBaseUrl/sessions/$sessionId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to end session');
    }
  }

  static Future<SessionModel> addToQueue(String sessionId, String kalamId) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/sessions/$sessionId/queue'),
      headers: await _authHeaders(),
      body: jsonEncode({'kalamId': kalamId}),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to add to queue');
  }

  static Future<SessionModel> removeFromQueue(String sessionId, String kalamId) async {
    final res = await http.delete(
      Uri.parse('$kBaseUrl/sessions/$sessionId/queue/$kalamId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to remove from queue');
  }

  static Future<SessionModel> reorderQueue(String sessionId, List<String> orderedIds) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl/sessions/$sessionId/queue/reorder'),
      headers: await _authHeaders(),
      body: jsonEncode({'orderedIds': orderedIds}),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to reorder queue');
  }

  static Future<SessionModel> skipToNext(String sessionId) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/sessions/$sessionId/queue/skip'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to skip to next');
  }

  // ─── Suggestions ──────────────────────────────────────────────────────────

  static Future<List<SuggestionModel>> getSuggestions(String sessionId) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/sessions/$sessionId/suggestions'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => SuggestionModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load suggestions');
  }

  static Future<SuggestionModel> suggestKalam(String sessionId, String kalamId) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/sessions/$sessionId/suggestions'),
      headers: await _authHeaders(),
      body: jsonEncode({'kalamId': kalamId}),
    );
    if (res.statusCode == 201) return SuggestionModel.fromJson(jsonDecode(res.body));
    throw Exception(_parseBody(res)['message'] ?? 'Failed to suggest kalam');
  }

  static Future<SuggestionModel> handleSuggestion(
      String sessionId, String sid, String status) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl/sessions/$sessionId/suggestions/$sid'),
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode == 200) return SuggestionModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to update suggestion');
  }

  // ─── Voting + advance ─────────────────────────────────────────────────────

  static Future<SessionModel> voteOnQueueItem(
      String sessionId, String kalaamId) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/sessions/$sessionId/queue/$kalaamId/vote'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception(_parseBody(res)['message'] ?? 'Failed to vote');
  }

  static Future<SessionModel> pinQueueItem(
    String sessionId,
    String kalaamId, {
    required bool pinned,
    int? pinPosition,
  }) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl/sessions/$sessionId/queue/$kalaamId/pin'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'pinned': pinned,
        if (pinPosition != null) 'pinPosition': pinPosition,
      }),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception(_parseBody(res)['message'] ?? 'Failed to pin queue item');
  }

  static Future<SessionModel> advanceToNext(String sessionId) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/sessions/$sessionId/advance'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return SessionModel.fromJson(jsonDecode(res.body));
    throw Exception(_parseBody(res)['message'] ?? 'Failed to advance');
  }

  // ─── Queue snapshots (history) ────────────────────────────────────────────

  static Future<List<QueueSnapshotSummary>> getQueueSnapshots(String groupId,
      {int limit = 10}) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/groups/$groupId/queue-snapshots?limit=$limit'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => QueueSnapshotSummary.fromJson(j)).toList();
    }
    throw Exception('Failed to load queue snapshots');
  }

  // ─── Invites ──────────────────────────────────────────────────────────────

  static Future<InviteCreatedResponse> createInvite(
    String groupId, {
    required String type, // 'permanent' or 'guest'
    int? ttlHours,
  }) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/groups/$groupId/invites'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'type': type,
        if (ttlHours != null) 'ttlHours': ttlHours,
      }),
    );
    if (res.statusCode == 201) {
      return InviteCreatedResponse.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseBody(res)['message'] ?? 'Failed to create invite');
  }

  static Future<InviteRedeemResponse> redeemInvite(String token) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/invites/$token/redeem'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      return InviteRedeemResponse.fromJson(jsonDecode(res.body));
    }
    throw Exception(_parseBody(res)['message'] ?? 'Failed to redeem invite');
  }
}

class InviteCreatedResponse {
  final String token;
  final String type;
  final DateTime expiresAt;
  final String link;
  InviteCreatedResponse({
    required this.token,
    required this.type,
    required this.expiresAt,
    required this.link,
  });
  factory InviteCreatedResponse.fromJson(Map<String, dynamic> j) =>
      InviteCreatedResponse(
        token: j['token'] as String,
        type: j['type'] as String,
        expiresAt: DateTime.parse(j['expiresAt'] as String),
        link: j['link'] as String,
      );
}

class InviteRedeemResponse {
  final String type; // 'permanent' or 'guest'
  final String groupId;
  final String groupName;
  final String? activeSessionId; // guest only
  InviteRedeemResponse({
    required this.type,
    required this.groupId,
    required this.groupName,
    this.activeSessionId,
  });
  factory InviteRedeemResponse.fromJson(Map<String, dynamic> j) =>
      InviteRedeemResponse(
        type: j['type'] as String,
        groupId: j['groupId'].toString(),
        groupName: (j['groupName'] as String?) ?? '',
        activeSessionId: j['activeSessionId']?.toString(),
      );
}

class QueueSnapshotSummary {
  final String id;
  final DateTime createdAt;
  final List<KalaamModel> items;
  QueueSnapshotSummary({
    required this.id,
    required this.createdAt,
    required this.items,
  });
  factory QueueSnapshotSummary.fromJson(Map<String, dynamic> j) {
    final rawItems = (j['items'] as List?) ?? const [];
    return QueueSnapshotSummary(
      id: (j['_id'] ?? j['id']).toString(),
      createdAt: DateTime.parse(j['createdAt'] as String),
      items: rawItems
          .whereType<Map>()
          .map((m) => KalaamModel.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class KalaamPage {
  final List<KalaamModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  const KalaamPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory KalaamPage.fromJson(Map<String, dynamic> json) => KalaamPage(
        items: (json['items'] as List? ?? [])
            .map((j) => KalaamModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        page: json['page'] ?? 1,
        limit: json['limit'] ?? 0,
        total: json['total'] ?? 0,
        hasMore: json['hasMore'] ?? false,
      );
}
