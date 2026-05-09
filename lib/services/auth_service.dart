import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Fetch user model from Firestore by uid
  Future<UserModel?> fetchUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  // Login with email and password
  Future<UserModel?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user == null) return null;
    return await fetchUser(cred.user!.uid);
  }

  // Register new user
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // Prevent self-registration as admin
    final safeRole = role == UserRole.admin ? UserRole.community : role;

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (cred.user == null) return null;

    final user = UserModel(
      id: cred.user!.uid,
      name: name,
      email: email,
      role: safeRole,
    );

    // Save to Firestore
    await _db.collection('users').doc(cred.user!.uid).set(user.toMap());

    // Update Firebase display name
    await cred.user!.updateDisplayName(name);

    return user;
  }

  // Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}