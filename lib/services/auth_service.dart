import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Returns the collection name based on role
  String _collectionForRole(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'admins';
      case UserRole.driver: return 'drivers';
      case UserRole.community: return 'community_users';
    }
  }

  // Fetch user by checking all 3 collections
  Future<UserModel?> fetchUser(String uid) async {
    for (final collection in ['admins', 'drivers', 'community_users']) {
      try {
        final doc = await _db.collection(collection).doc(uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.id, doc.data()!);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<UserModel?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user == null) return null;
    return await fetchUser(cred.user!.uid);
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
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

    // Save to the correct collection
    await _db
        .collection(_collectionForRole(safeRole))
        .doc(cred.user!.uid)
        .set(user.toMap());

    await cred.user!.updateDisplayName(name);
    return user;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}