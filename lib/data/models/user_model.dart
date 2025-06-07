class UserModel {
  final String name;
  final String email;
  final int notifications;

  UserModel({
    required this.name,
    required this.email,
    required this.notifications,
  });
}

class UserProfileModel {
  final String id;
  final String username;
  final String whatsapp;
  final String role;
  final String avatarUrl;
  final DateTime updatedAt;

  UserProfileModel({
    required this.id,
    required this.username,
    required this.whatsapp,
    required this.role,
    required this.avatarUrl,
    required this.updatedAt,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['user_id'] ?? '',
      username: map['username'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      role: map['role'] ?? '',
      avatarUrl: map['avatar_url'] ?? '',
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': id,
      'username': username,
      'whatsapp': whatsapp,
      'role': role,
      'avatar_url': avatarUrl,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

const List<String> allowedRoles = [
  'Admin',
  'Manager',
  'PP',
  'Teknik',
  'TE',
  'Vendor',
];

String getRoleLabel(String? role) {
  if (role == null || !allowedRoles.contains(role)) return '-';
  return role;
}
