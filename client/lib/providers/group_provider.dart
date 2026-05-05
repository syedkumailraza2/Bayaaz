import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/session_model.dart';
import '../services/api_service.dart';

class GroupProvider extends ChangeNotifier {
  List<GroupModel> _groups = [];
  bool _loading = false;
  String? _error;

  List<GroupModel> get groups => List.unmodifiable(_groups);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadGroups() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await ApiService.getGroups();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(String name) async {
    try {
      final group = await ApiService.createGroup(name);
      _groups.insert(0, group);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addMember(String groupId, String userId) async {
    try {
      final updated = await ApiService.addMember(groupId, userId);
      _replaceGroup(updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeMember(String groupId, String userId) async {
    try {
      final updated = await ApiService.removeMember(groupId, userId);
      _replaceGroup(updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<SessionModel?> startSession(String groupId) async {
    try {
      return await ApiService.startSession(groupId);
    } catch (e) {
      return null;
    }
  }

  Future<SessionModel?> getActiveSession(String groupId) async {
    try {
      return await ApiService.getActiveSession(groupId);
    } catch (e) {
      return null;
    }
  }

  void _replaceGroup(GroupModel updated) {
    final idx = _groups.indexWhere((g) => g.id == updated.id);
    if (idx != -1) {
      _groups[idx] = updated;
    } else {
      _groups.insert(0, updated);
    }
    notifyListeners();
  }
}
