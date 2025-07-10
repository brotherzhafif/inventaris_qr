class User {
  final int? id;
  final String username;
  final String password;
  final String fullName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'full_name': fullName,
      'role': role.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      fullName: map['full_name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.viewer,
      ),
      createdAt: DateTime.parse(map['created_at']),
      lastLogin: map['last_login'] != null
          ? DateTime.parse(map['last_login'])
          : null,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? fullName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  // Convenience methods that delegate to UserRole extension
  bool get canManageUsers => role.canManageUsers;
  bool get canManageItems => role.canManageItems;
  bool get canViewReports => role.canViewReports;
  bool get canScanBarcode => role.canScanBarcode;
  bool get canManageTransactions => role.canManageTransactions;
}

enum UserRole { admin, petugas, viewer }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.petugas:
        return 'Petugas';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  bool get canManageUsers => this == UserRole.admin;
  bool get canManageItems => this == UserRole.admin || this == UserRole.petugas;
  bool get canViewReports => true;
  bool get canScanBarcode => this == UserRole.admin || this == UserRole.petugas;
  bool get canManageTransactions =>
      this == UserRole.admin || this == UserRole.petugas;
}
