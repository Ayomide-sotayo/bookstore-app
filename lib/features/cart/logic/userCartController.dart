import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserCartController {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// Add book to user's cart
  Future<void> addToCart(Map<String, dynamic> book) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(book['bookId']) // prevent duplicates
        .set({
      ...book,
      'uid': user.uid,
      'quantity': 1,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove book from cart
  Future<void> removeFromCart(String bookId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(bookId)
        .delete();
  }

  /// Clear cart
  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final cartRef = _db.collection('users').doc(user.uid).collection('cart');
    final snapshot = await cartRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
