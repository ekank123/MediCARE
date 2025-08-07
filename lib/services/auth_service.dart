import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicare_plus/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _createUserProfile(userCredential.user!.uid, name, email);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(String uid, String name, String email) async {
    final userModel = UserModel(
      id: uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(userModel.toMap());
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get user data (alias for getUserProfile)
  Future<UserModel?> getUserData(String uid) async {
    return getUserProfile(uid);
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel userModel) async {
    try {
      await _firestore.collection('users').doc(userModel.id).update(userModel.toMap());
    } catch (e) {
      rethrow;
    }
  }
  
  // Update user data
  Future<void> updateUserData(UserModel userModel) async {
    try {
      await _firestore.collection('users').doc(userModel.id).update(userModel.toMap());
      
      // Update display name if user is signed in
      if (_auth.currentUser != null && userModel.name.isNotEmpty) {
        await _auth.currentUser!.updateDisplayName(userModel.name);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update display name
  Future<void> updateDisplayName(String name) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(name);
        
        // Also update in Firestore
        if (_auth.currentUser!.uid.isNotEmpty) {
          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
            'name': name,
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // This would require google_sign_in package and additional setup
      // Implementation would go here
      throw UnimplementedError('Google Sign In not implemented yet');
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // This would require additional setup for Apple Sign In
      // Implementation would go here
      throw UnimplementedError('Apple Sign In not implemented yet');
    } catch (e) {
      rethrow;
    }
  }
}