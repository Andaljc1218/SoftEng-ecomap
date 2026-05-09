enum UserRole { admin, driver, community }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profilePicture;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profilePicture,
  });

  String get roleLabel {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.driver:
        return 'Garbage Collection Driver';
      case UserRole.community:
        return 'Community User';
    }
  }

  // Convert role enum to string for Firestore
  static String roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'admin';
      case UserRole.driver: return 'driver';
      case UserRole.community: return 'community';
    }
  }

  // Convert Firestore string back to role enum
  static UserRole roleFromString(String role) {
    switch (role) {
      case 'admin': return UserRole.admin;
      case 'driver': return UserRole.driver;
      default: return UserRole.community;
    }
  }

  // Create from Firestore document
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: roleFromString(map['role'] ?? 'community'),
      profilePicture: map['profilePicture'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': roleToString(role),
      if (profilePicture != null) 'profilePicture': profilePicture,
    };
  }
}