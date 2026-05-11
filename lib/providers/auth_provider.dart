import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get role => _currentUser?.role;
  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();

    final firebaseUser = _service.currentFirebaseUser;
    if (firebaseUser != null) {
      _currentUser = await _service.fetchUser(firebaseUser.uid);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _service.login(email, password);
      if (_currentUser == null) {
        _errorMessage = 'User data not found. Contact support.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = _friendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _service.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      if (_currentUser == null) {
        _errorMessage = 'Registration failed. Try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = _friendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateName(String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateName(
        _currentUser!.id,
        name,
        _currentUser!.role,
      );
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: name,
        email: _currentUser!.email,
        role: _currentUser!.role,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = _friendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.changePassword(
        email: _currentUser!.email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = _friendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _service.sendPasswordReset(email);
      return true;
    } on Exception {
      return false;
    }
  }

  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteAccount(
        uid: _currentUser!.id,
        role: _currentUser!.role,
        email: _currentUser!.email,
        password: password,
      );
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = _friendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }
    if (raw.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (raw.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (raw.contains('network-request-failed')) {
      return 'No internet connection. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}