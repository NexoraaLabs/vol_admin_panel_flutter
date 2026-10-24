/// The signed-in account, from the `user` of an admin session. Only the fields the panel shows.
class AdminUser {
  const AdminUser({required this.id, required this.name, required this.email, required this.role, this.avatarUrl});

  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;

  /// Panel screens need an admin or moderator.
  bool get isStaff => role == 'ADMIN' || role == 'MODERATOR';

  /// Only ADMIN (not MODERATOR) can open platform configuration screens.
  bool get isAdmin => role == 'ADMIN';

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? 'USER',
    avatarUrl: json['avatarUrl'] as String?,
  );
}
