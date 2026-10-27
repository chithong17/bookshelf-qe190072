import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.favorite,
    required this.notes,
    required this.createdAt,
    this.rating,
  });

  static const genres = ['Fiction', 'Non-Fiction', 'Academic', 'Other'];
  static const statuses = ['To Read', 'Reading', 'Finished'];

  final String id;
  final String userId;
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String notes;
  final DateTime createdAt;

  factory Book.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Book(
      id: data['id'] as String,
      userId: data['userId'] as String,
      title: data['title'] as String,
      author: data['author'] as String,
      genre: data['genre'] as String,
      status: data['status'] as String,
      rating: data['rating'] as int?,
      favorite: data['favorite'] as bool,
      notes: data['notes'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'userId': userId,
      'title': title.trim(),
      'author': author.trim(),
      'genre': genre,
      'status': status,
      'favorite': favorite,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (rating != null) map['rating'] = rating;
    return map;
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? genre,
    String? status,
    int? rating,
    bool clearRating = false,
    bool? favorite,
    String? notes,
  }) => Book(
    id: id ?? this.id,
    userId: userId,
    title: title ?? this.title,
    author: author ?? this.author,
    genre: genre ?? this.genre,
    status: status ?? this.status,
    rating: clearRating ? null : (rating ?? this.rating),
    favorite: favorite ?? this.favorite,
    notes: notes ?? this.notes,
    createdAt: createdAt,
  );
}
