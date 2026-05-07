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
}