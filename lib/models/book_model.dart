import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String ownerId;
  final String? imageUrl;
  final Timestamp createdAt;
  final bool isAvailable;
  final String? category; // YENİ ALAN EKLENDİ

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.ownerId,
    this.imageUrl,
    required this.createdAt,
    required this.isAvailable,
    this.category, // CONSTRUCTOR'A EKLENDİ (opsiyonel olduğu için required değil)
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      imageUrl: data['imageUrl'] as String?, // String? olarak cast et
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isAvailable: data['isAvailable'] ?? true,
      category:
          data['category']
              as String?, // FROMFIRESTORE'A EKLENDİ (String? olarak cast et)
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'ownerId': ownerId,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'isAvailable': isAvailable,
      'category': category, // TOFIRESTORE'A EKLENDİ
    };
  }
}
