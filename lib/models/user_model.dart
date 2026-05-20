// lib/models/user_model.dart

enum UserRole {
  admin,
  general
}

extension UserRoleExt on UserRole {
  String get value => name;  // Returns 'admin' or 'general' (matches DB)

  String get label => this == UserRole.admin ? 'Admin' : 'General';

  bool get isAdmin => this == UserRole.admin;

  // Factory method to convert from DB string
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'general':
        return UserRole.general;
      default:
        return UserRole.general;
    }
  }
}

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final UserRole role;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.role = UserRole.general,
    required this.createdAt,
  });

  bool get isAdmin => role.isAdmin;

  factory UserProfile.fromMap(Map<String, dynamic> map, String email) {
    return UserProfile(
      id: map['id'] ?? '',
      email: email,
      fullName: map['full_name'] ?? '',
      phone: map['phone'],
      avatarUrl: map['avatar_url'],
      bio: map['bio'],
      role: UserRoleExt.fromString(map['role'] ?? 'general'),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? bio,
    UserRole? role,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'bio': bio,
      'role': role.value,
      'created_at': createdAt.toIso8601String(),
    };
  }
}