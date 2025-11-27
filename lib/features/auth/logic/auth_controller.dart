import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SIGN UP (with username)
  Future<String?> signUp(String username, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username,
          'email': user.email,
          'isDisabled': false,
        });
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An error occurred";
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if the user is disabled
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .get();

      if (doc.exists && (doc.data()?['isDisabled'] ?? false)) {
        await _auth.signOut();
        return "This account has been disabled";
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An error occurred";
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // CURRENT USER
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
