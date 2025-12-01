import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../constants/app_constants.dart';
import '../models/user.dart';
import '../models/lyric.dart';
import '../models/category.dart';
import 'storage_service.dart';

class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();

  ApiService._();

  final String _baseUrl = AppConstants.baseUrl;
  String? _authToken;

  String? get authToken => _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  bool get isAuthenticated => _authToken != null;

  // Helper methods
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final requestHeaders = {..._headers, ...?headers};

    debugPrint('API Request: $method $uri');
    if (body != null) {
      debugPrint('Request Body: ${jsonEncode(body)}');
    }

    try {
      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(uri, headers: requestHeaders)
              .timeout(timeout ?? AppConstants.apiTimeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: requestHeaders, body: jsonEncode(body))
              .timeout(timeout ?? AppConstants.apiTimeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: requestHeaders, body: jsonEncode(body))
              .timeout(timeout ?? AppConstants.apiTimeout);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: requestHeaders)
              .timeout(timeout ?? AppConstants.apiTimeout);
          break;
        case 'PATCH':
          response = await http
              .patch(uri, headers: requestHeaders, body: jsonEncode(body))
              .timeout(timeout ?? AppConstants.apiTimeout);
          break;
        default:
          throw UnsupportedError('HTTP method $method is not supported');
      }

      debugPrint('API Response: ${response.statusCode} ${response.body}');

      return response;
    } on SocketException {
      throw NetworkException('No internet connection');
    } on HttpException {
      throw HttpException('HTTP error occurred');
    } on FormatException {
      throw FormatException('Invalid response format');
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  Future<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {} as T;
      }

      try {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return fromJson(jsonResponse);
      } catch (e) {
        throw FormatException('Failed to parse response: $e');
      }
    } else {
      final errorMessage = _parseErrorMessage(response);
      throw ApiException(response.statusCode, errorMessage);
    }
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final Map<String, dynamic> errorResponse = jsonDecode(response.body);
      return errorResponse['message'] ?? errorResponse['error'] ?? 'Unknown error occurred';
    } catch (e) {
      return 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}';
    }
  }

  // Authentication endpoints
  Future<User> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final response = await _makeRequest('POST', '/auth/register', body: {
      'username': username,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });

    return _handleResponse(response, (json) {
      final userData = json['user'];
      final token = json['token'];
      setAuthToken(token);
      return User.fromJson(userData);
    });
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _makeRequest('POST', '/auth/login', body: {
      'email': email,
      'password': password,
    });

    return _handleResponse(response, (json) {
      final userData = json['user'];
      final token = json['token'];
      setAuthToken(token);
      return User.fromJson(userData);
    });
  }

  Future<User> getProfile() async {
    final response = await _makeRequest('GET', '/auth/profile');
    return _handleResponse(response, (json) => User.fromJson(json['user']));
  }

  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
  }) async {
    final response = await _makeRequest('PUT', '/auth/profile', body: {
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
    });

    return _handleResponse(response, (json) => User.fromJson(json['user']));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _makeRequest('PUT', '/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });

    _handleResponse(response, (json) => json);
  }

  Future<void> logout() async {
    try {
      await _makeRequest('POST', '/auth/logout');
    } catch (e) {
      // Continue with logout even if server call fails
      debugPrint('Logout API call failed: $e');
    } finally {
      setAuthToken(null);
      await StorageService.instance.removeToken();
      await StorageService.instance.removeCurrentUser();
    }
  }

  // Lyrics endpoints
  Future<List<Lyric>> getLyrics({
    int page = 1,
    int limit = 20,
    String? categoryId,
    List<String>? tags,
    String? poet,
    int? year,
    String? search,
    bool? isFavorite,
    bool? isPinned,
    String sortBy = 'recent',
    String status = 'published',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'status': status,
    };

    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');
    if (poet != null) queryParams['poet'] = poet;
    if (year != null) queryParams['year'] = year.toString();
    if (search != null) queryParams['search'] = search;
    if (isFavorite != null) queryParams['isFavorite'] = isFavorite.toString();
    if (isPinned != null) queryParams['isPinned'] = isPinned.toString();

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint = '/lyrics?$queryString';

    final response = await _makeRequest('GET', endpoint);

    return _handleResponse(response, (json) {
      final lyricsData = json['lyrics'] as List;
      return lyricsData.map((lyric) => Lyric.fromJson(lyric)).toList();
    });
  }

  Future<Lyric> getLyricById(String id) async {
    final response = await _makeRequest('GET', '/lyrics/$id');
    return _handleResponse(response, (json) => Lyric.fromJson(json['lyric']));
  }

  Future<Lyric> createLyric({
    required String title,
    required String content,
    required String categoryId,
    String? poet,
    int? year,
    List<String>? tags,
    String? language,
    Map<String, dynamic>? metadata,
    String? status,
    String? visibility,
    bool? isLocked,
    String? lockPin,
  }) async {
    final response = await _makeRequest('POST', '/lyrics', body: {
      'title': title,
      'content': content,
      'categoryId': categoryId,
      if (poet != null) 'poet': poet,
      if (year != null) 'year': year,
      if (tags != null) 'tags': tags,
      if (language != null) 'language': language,
      if (metadata != null) 'metadata': metadata,
      if (status != null) 'status': status,
      if (visibility != null) 'visibility': visibility,
      if (isLocked != null) 'isLocked': isLocked,
      if (lockPin != null) 'lockPin': lockPin,
    });

    return _handleResponse(response, (json) => Lyric.fromJson(json['lyric']));
  }

  Future<Lyric> updateLyric(String id, Map<String, dynamic> updates) async {
    final response = await _makeRequest('PUT', '/lyrics/$id', body: updates);
    return _handleResponse(response, (json) => Lyric.fromJson(json['lyric']));
  }

  Future<void> deleteLyric(String id, {String? pin}) async {
    final body = <String, dynamic>{};
    if (pin != null) body['pin'] = pin;

    final response = await _makeRequest('DELETE', '/lyrics/$id', body: body);
    _handleResponse(response, (json) => json);
  }

  Future<Lyric> toggleFavorite(String id) async {
    final response = await _makeRequest('POST', '/lyrics/$id/favorite');
    return _handleResponse(response, (json) {
      final lyricData = json['lyric'] ?? json;
      return Lyric.fromJson(lyricData);
    });
  }

  Future<Lyric> togglePin(String id) async {
    final response = await _makeRequest('POST', '/lyrics/$id/pin');
    return _handleResponse(response, (json) {
      final lyricData = json['lyric'] ?? json;
      return Lyric.fromJson(lyricData);
    });
  }

  // Categories endpoints
  Future<List<Category>> getCategories({bool includeArchived = false}) async {
    final endpoint = '/categories?includeArchived=$includeArchived';
    final response = await _makeRequest('GET', endpoint);

    return _handleResponse(response, (json) {
      final categoriesData = json['categories'] as List;
      return categoriesData.map((category) => Category.fromJson(category)).toList();
    });
  }

  Future<Category> createCategory({
    required String name,
    String? description,
    String? color,
    String? icon,
  }) async {
    final response = await _makeRequest('POST', '/categories', body: {
      'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
    });

    return _handleResponse(response, (json) => Category.fromJson(json['category']));
  }

  Future<Category> updateCategory(String id, Map<String, dynamic> updates) async {
    final response = await _makeRequest('PUT', '/categories/$id', body: updates);
    return _handleResponse(response, (json) => Category.fromJson(json['category']));
  }

  Future<void> deleteCategory(String id) async {
    final response = await _makeRequest('DELETE', '/categories/$id');
    _handleResponse(response, (json) => json);
  }

  // User dashboard and data endpoints
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _makeRequest('GET', '/users/dashboard');
    return _handleResponse(response, (json) => json);
  }

  Future<Map<String, dynamic>> searchContent({
    required String query,
    String type = 'all',
    int limit = 20,
    int page = 1,
    String sortBy = 'relevance',
  }) async {
    final queryParams = <String, String>{
      'q': query,
      'type': type,
      'limit': limit.toString(),
      'page': page.toString(),
      'sortBy': sortBy,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint = '/users/search?$queryString';

    final response = await _makeRequest('GET', endpoint);
    return _handleResponse(response, (json) => json);
  }

  Future<Map<String, dynamic>> exportData({String format = 'json'}) async {
    final endpoint = '/users/export?format=$format';
    final response = await _makeRequest('GET', endpoint);
    return _handleResponse(response, (json) => json);
  }

  Future<Map<String, dynamic>> importData({
    required Map<String, dynamic> data,
    String mergeStrategy = 'replace',
  }) async {
    final response = await _makeRequest('POST', '/users/import', body: {
      'data': data,
      'mergeStrategy': mergeStrategy,
    });

    return _handleResponse(response, (json) => json);
  }

  Future<Map<String, dynamic>> syncData({DateTime? lastSyncTime}) async {
    final body = <String, dynamic>{};
    if (lastSyncTime != null) {
      body['lastSyncTime'] = lastSyncTime.toIso8601String();
    }

    final response = await _makeRequest('POST', '/users/sync', body: body);
    return _handleResponse(response, (json) => json);
  }

  // File upload endpoints
  Future<Map<String, dynamic>> uploadImages(List<File> images) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload/images'),
    );

    request.headers.addAll(_headers);

    for (final image in images) {
      final stream = http.ByteStream(image.openRead());
      final length = await image.length();
      final multipartFile = http.MultipartFile('images', stream, length, filename: image.path.split('/').last);
      request.files.add(multipartFile);
    }

    try {
      final streamedResponse = await request.send().timeout(AppConstants.apiTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload Images Response: ${response.statusCode} ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw ApiException(response.statusCode, errorMessage);
      }
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<Map<String, dynamic>> uploadAudio(File audio) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload/audio'),
    );

    request.headers.addAll(_headers);

    final stream = http.ByteStream(audio.openRead());
    final length = await audio.length();
    final multipartFile = http.MultipartFile('audio', stream, length, filename: audio.path.split('/').last);
    request.files.add(multipartFile);

    try {
      final streamedResponse = await request.send().timeout(AppConstants.apiTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload Audio Response: ${response.statusCode} ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw ApiException(response.statusCode, errorMessage);
      }
    } catch (e) {
      throw Exception('Audio upload failed: $e');
    }
  }

  // Health check
  Future<bool> checkServerHealth() async {
    try {
      final response = await _makeRequest('GET', '/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Custom exceptions
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}