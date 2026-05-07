import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get role => _currentUser?.role;

  // Mock login — replace with Firebase Auth later
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    // Mock users for testing all three roles
    if (email == 'admin@ecomap.com') {
      _currentUser = const UserModel(
        id: '1',
        name: 'Admin User',
        email: 'admin@ecomap.com',
        role: UserRole.admin,
      );
    } else if (email == 'driver@ecomap.com') {
      _currentUser = const UserModel(
        id: '2',
        name: 'Juan dela Cruz',
        email: 'driver@ecomap.com',
        role: UserRole.driver,
      );
    } else {
      _currentUser = UserModel(
        id: '3',
        name: email.split('@').first,
        email: email,
        role: UserRole.community,
      );
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _currentUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}