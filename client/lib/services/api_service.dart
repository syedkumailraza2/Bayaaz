import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kalaam_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/session_model.dart';
import '../models/suggestion_model.dart';

// Change to your machine's IP when testing on a physical device
// const String kBaseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
// const String kBaseUrl = 'http://localhost:3000/api'; // iOS simulator
const String kBaseUrl = 'https://bayaaz.onrender.com/api'; // ngrok (physical device)

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

  // Kalaams
  static Future<List<KalaamModel>> getPublicKalaams({String? category}) async {
    final uri = Uri.parse('$kBaseUrl/kalaams')
        .replace(queryParameters: category != null ? {'category': category} : null);
    final res = await http.get(uri, headers: await _authHeaders());
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => KalaamModel.fromJson(j)).toList();
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

  static Future<Map<String, dynamic>> toggleSave(String id) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/kalaams/$id/save'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to save kalaam');
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
    );
    if (res.statusCode == 200) return GroupModel.fromJson(jsonDecode(res.body));
    throw Exception('Failed to load group');
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

  static Future<SessionModel> startSession(String groupId) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/groups/$groupId/sessions'),
      headers: await _authHeaders(),
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
}
