class GroupMember {
  final String id;
  final String name;
  final String? avatar;
  final String role; // 'admin' | 'member'

  GroupMember({
    required this.id,
    required this.name,
    this.avatar,
    required this.role,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json, List<dynamic> roles) {
    final userId = json['_id'] ?? json['id'] ?? '';
    final roleEntry = roles.firstWhere(
      (r) {
        final ru = r['userId'];
        if (ru == userId) return true;
        if (ru is Map && ru['_id'] == userId) return true;
        return false;
      },
      orElse: () => {'role': 'member'},
    );
    return GroupMember(
      id: userId,
      name: json['name'] ?? '',
      avatar: json['avatar'],
      role: roleEntry['role'] ?? 'member',
    );
  }
}

class GroupModel {
  final String id;
  final String name;
  final String createdById;
  final List<GroupMember> members;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdById,
    required this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'] as List? ?? [];
    final rawMembers = json['members'] as List? ?? [];
    return GroupModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      createdById:
          (json['createdBy'] is Map ? json['createdBy']['_id'] : json['createdBy']) ?? '',
      members: rawMembers
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>, roles))
          .toList(),
    );
  }
}
