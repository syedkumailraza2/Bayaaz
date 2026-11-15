class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;

  /// 'admin' or 'user'. Only admins can create kalaams (enforced server-side;
  /// the app just hides the create entry points for everyone else).
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? json['_id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        avatar: json['avatar'],
        role: (json['role'] as String?) ?? 'user',
      );
}
