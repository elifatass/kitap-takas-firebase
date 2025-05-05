import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id; // Firestore doküman ID'si
  final String title;
  final String author;
  final String description;
  final String ownerId; // Kitabı ekleyen kullanıcının UID'si
  final String? imageUrl; // Resim URL'si (opsiyonel, ? ile nullable)
  final Timestamp createdAt; // Eklenme zamanı
  final bool isAvailable; // Takasa uygun mu?

  // Constructor
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.ownerId,
    this.imageUrl, // Opsiyonel olduğu için required değil
    required this.createdAt,
    required this.isAvailable,
    // TODO: Diğer alanlar eklenebilir (ISBN, durum, kategori vb.)
  });

  // Firestore'dan gelen Map verisini Book nesnesine dönüştüren factory constructor
  // Bu, veriyi okurken çok işimize yarayacak.
  factory Book.fromFirestore(DocumentSnapshot doc) {
    // Gelen veriyi Map olarak alıyoruz
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Book(
      id: doc.id, // Dokümanın ID'sini alıyoruz
      title: data['title'] ?? '', // Null ise boş string ata
      author: data['author'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      imageUrl: data['imageUrl'], // Null olabilir, direkt ata
      createdAt:
          data['createdAt'] ?? Timestamp.now(), // Null ise şimdiki zamanı ata
      isAvailable: data['isAvailable'] ?? true, // Null ise true kabul et
      // TODO: Diğer alanları da ekle
    );
  }

  // Book nesnesini Firestore'a yazmak için Map'e dönüştüren metot (Opsiyonel)
  // Bu genellikle servis katmanında yapılır ama modelde de olabilir.
  Map<String, dynamic> toFirestore() {
    return {
      // 'id' Firestore tarafından otomatik verildiği için genellikle eklenmez
      'title': title,
      'author': author,
      'description': description,
      'ownerId': ownerId,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'isAvailable': isAvailable,
      // TODO: Diğer alanları da ekle
    };
  }
}
