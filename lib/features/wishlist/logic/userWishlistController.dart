import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserWishlistController {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Add book to wishlist
  Future<void> addToWishlist(Map<String, dynamic> book) async {
    await _db.collection('users').doc(_uid).update({
      'wishlist': FieldValue.arrayUnion([book]),
    });
  }

  /// Remove book from wishlist
  Future<void> removeFromWishlist(Map<String, dynamic> book) async {
    await _db.collection('users').doc(_uid).update({
      'wishlist': FieldValue.arrayRemove([book]),
    });
  }

  /// Get wishlist in real-time
  Stream<List<Map<String, dynamic>>> getWishlistStream() {
    return _db.collection('users').doc(_uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data['wishlist'] == null) return [];
      return List<Map<String, dynamic>>.from(data['wishlist']);
    });
  }
}
