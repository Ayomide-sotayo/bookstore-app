import 'package:cloud_firestore/cloud_firestore.dart';

class UserAdminController {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

  /// Real-time stream of all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return usersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'email': data['email'],
          'username': data['username'] ?? '', // Added username
          'isDisabled': data['isDisabled'] ?? false,
        };
      }).toList();
    });
  }

  /// Toggle disable/enable user
  Future<void> toggleDisable(String uid, bool isDisabled) async {
    await usersRef.doc(uid).update({'isDisabled': isDisabled});
  }

  /// Delete user document from Firestore
  Future<void> deleteUser(String uid) async {
    await usersRef.doc(uid).delete();
  }

  /// Optional: one-time fetch (not used in current UI)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await usersRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'email': data['email'],
        'username': data['username'] ?? '', // Added username
        'isDisabled': data['isDisabled'] ?? false,
      };
    }).toList();
  }
}
