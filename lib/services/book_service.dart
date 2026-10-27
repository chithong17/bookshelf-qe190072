import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class BookService {
  BookService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _books =>
      _firestore.collection('books');

  static String idFor(String userId, String title, String author) {
    String hex(String value) => utf8
        .encode(value.trim().toLowerCase())
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join();
    return '${userId}__${hex(title)}__${hex(author)}';
  }

  Stream<List<Book>> watchBooks(String userId) => _books
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Book.fromDocument).toList());

  Future<void> addBook({
    required String userId,
    required String title,
    required String author,
    required String genre,
    required String status,
    required int? rating,
    required String notes,
  }) async {
    final id = idFor(userId, title, author);
    final ref = _books.doc(id);
    await _firestore.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) {
        throw const DuplicateBookException();
      }
      final book = Book(
        id: id,
        userId: userId,
        title: title.trim(),
        author: author.trim(),
        genre: genre,
        status: status,
        rating: rating,
        favorite: false,
        notes: notes,
        createdAt: DateTime.now(),
      );
      transaction.set(ref, book.toMap());
    });
  }

  Future<Book> updateBook(Book original, Book updated) async {
    final newId = idFor(original.userId, updated.title, updated.author);
    final normalized = updated.copyWith(id: newId);
    final oldRef = _books.doc(original.id);
    final newRef = _books.doc(newId);
    await _firestore.runTransaction((transaction) async {
      if (newId != original.id && (await transaction.get(newRef)).exists) {
        throw const DuplicateBookException();
      }
      transaction.set(newRef, normalized.toMap());
      if (newId != original.id) transaction.delete(oldRef);
    });
    return normalized;
  }

  Future<void> toggleFavorite(Book book) =>
      _books.doc(book.id).update({'favorite': !book.favorite});
  Future<void> deleteBook(Book book) => _books.doc(book.id).delete();
}

class DuplicateBookException implements Exception {
  const DuplicateBookException();
  @override
  String toString() => 'A book with the same title and author already exists';
}
