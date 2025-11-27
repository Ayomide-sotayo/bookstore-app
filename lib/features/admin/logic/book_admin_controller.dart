// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class BookAdminController {
  final _db = FirebaseFirestore.instance;
  final _booksRef = FirebaseFirestore.instance.collection('books');

  /// Add new book
  Future<void> addBook(BookModel book) async {
    try {
      final doc = _booksRef.doc();
      final newBook = book.copyWith(id: doc.id);
      await doc.set(newBook.toMap());
      print("✅ Book added: ${newBook.title}");
    } catch (e) {
      print("❌ Failed to add book: $e");
      rethrow;
    }
  }

  /// Update existing book
  Future<void> updateBook(BookModel book) async {
    try {
      await _booksRef.doc(book.id).update(book.toMap());
      print("✅ Book updated: ${book.title}");
    } catch (e) {
      print("❌ Failed to update book: $e");
      rethrow;
    }
  }

  /// Delete book
  Future<void> deleteBook(String bookId) async {
    try {
      await _booksRef.doc(bookId).delete();
      print("🗑️ Book deleted: $bookId");
    } catch (e) {
      print("❌ Failed to delete book: $e");
      rethrow;
    }
  }

  /// Fetch all books stream (real-time)
  Stream<List<BookModel>> getBooksStream() {
    return _booksRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Fetch all books once (e.g. on load)
  Future<List<BookModel>> getAllBooks() async {
    try {
      final snapshot = await _booksRef.get();
      return snapshot.docs.map((doc) {
        return BookModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print("❌ Error fetching books: $e");
      return [];
    }
  }
}
