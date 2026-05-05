import 'package:flutter/material.dart';
import '../models/kalaam_model.dart';
import '../services/api_service.dart';

class KalaamProvider extends ChangeNotifier {
  List<KalaamModel> _feed = [];
  List<KalaamModel> _myKalaams = [];
  List<KalaamModel> _savedKalaams = [];
  Set<String> _savedIds = {};
  bool _feedLoading = false;
  bool _myLoading = false;
  bool _savedLoading = false;
  String? _feedError;
  String? _myError;
  String? _savedError;
  String? _selectedCategory;
  String _searchQuery = '';
  String? _selectedTag;

  List<KalaamModel> get feed => _feed;
  List<KalaamModel> get myKalaams => _myKalaams;
  List<KalaamModel> get savedKalaams => _savedKalaams;
  Set<String> get savedIds => _savedIds;
  bool get feedLoading => _feedLoading;
  bool get myLoading => _myLoading;
  bool get savedLoading => _savedLoading;
  String? get feedError => _feedError;
  String? get myError => _myError;
  String? get savedError => _savedError;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;

  List<KalaamModel> get filteredFeed {
    var result = _feed;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((k) {
        if (k.title.toLowerCase().contains(q)) return true;
        return k.content.any((stanza) => stanza.lines.any((line) => line.toLowerCase().contains(q)));
      }).toList();
    }
    if (_selectedTag != null) {
      result = result.where((k) => k.tags.contains(_selectedTag)).toList();
    }
    return result;
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setTagFilter(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  bool isSaved(String id) => _savedIds.contains(id);

  Future<void> loadFeed({String? category}) async {
    _feedLoading = true;
    _feedError = null;
    _selectedCategory = category;
    notifyListeners();
    try {
      _feed = await ApiService.getPublicKalaams(category: category);
    } catch (e) {
      _feedError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _feedLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyKalaams() async {
    _myLoading = true;
    _myError = null;
    notifyListeners();
    try {
      _myKalaams = await ApiService.getMyKalaams();
    } catch (e) {
      _myError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _myLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedKalaams() async {
    _savedLoading = true;
    _savedError = null;
    notifyListeners();
    try {
      _savedKalaams = await ApiService.getSavedKalaams();
      _savedIds = _savedKalaams.map((k) => k.id).toSet();
    } catch (e) {
      _savedError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _savedLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleSave(String id) async {
    try {
      final result = await ApiService.toggleSave(id);
      final wasSaved = result['saved'] as bool;
      if (wasSaved) {
        _savedIds.add(id);
      } else {
        _savedIds.remove(id);
        _savedKalaams.removeWhere((k) => k.id == id);
      }
      notifyListeners();
      return wasSaved;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleVisibility(String id) async {
    try {
      final updated = await ApiService.toggleVisibility(id);
      final idx = _myKalaams.indexWhere((k) => k.id == id);
      if (idx != -1) {
        _myKalaams[idx] = updated;
        // sync feed
        final feedIdx = _feed.indexWhere((k) => k.id == id);
        if (updated.isPublic && feedIdx == -1) {
          _feed.insert(0, updated);
        } else if (!updated.isPublic && feedIdx != -1) {
          _feed.removeAt(feedIdx);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addKalaam({
    required String title,
    required List<Map<String, dynamic>> content,
    required String category,
    required bool isPublic,
    String? poet,
    List<String> tags = const [],
  }) async {
    try {
      final kalaam = await ApiService.createKalaam(
        title: title,
        content: content,
        category: category,
        isPublic: isPublic,
        poet: poet,
        tags: tags,
      );
      _myKalaams.insert(0, kalaam);
      if (isPublic) _feed.insert(0, kalaam);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteKalaam(String id) async {
    try {
      await ApiService.deleteKalaam(id);
      _myKalaams.removeWhere((k) => k.id == id);
      _feed.removeWhere((k) => k.id == id);
      _savedKalaams.removeWhere((k) => k.id == id);
      _savedIds.remove(id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
