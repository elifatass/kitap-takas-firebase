import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Kullanıcı UID'si için

class FirestoreService {
  // Firestore instance'ını alalım
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // FirebaseAuth instance'ını alalım (mevcut kullanıcıyı almak için)
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Kitap İşlemleri ---

  // Kitaplar koleksiyonuna referans (daha kolay erişim için)
  final CollectionReference _booksCollection = FirebaseFirestore.instance
      .collection('books');

  // Yeni Kitap Ekleme
  Future<void> addBook({
    required String title,
    required String author,
    required String description,
    String? imageUrl, // Opsiyonel resim URL'si
    // TODO: Diğer kitap alanları eklenebilir (ISBN, durum, kategori vb.)
  }) async {
    try {
      // Giriş yapmış kullanıcının UID'sini al
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        print("Hata: Kitap eklemek için kullanıcı girişi gerekli.");
        // İdeal olarak burada bir hata fırlatılabilir veya null döndürülebilir
        return;
      }

      // Yeni kitap dokümanı oluştur
      await _booksCollection.add({
        'title': title,
        'author': author,
        'description': description,
        'imageUrl': imageUrl, // Null olabilir
        'ownerId': userId, // Kitabı ekleyen kullanıcının ID'si
        'createdAt': Timestamp.now(), // Eklenme zamanı
        'isAvailable': true, // Başlangıçta takasa uygun
        // TODO: Diğer alanlar...
      });
      print("Kitap başarıyla Firestore'a eklendi.");
    } catch (e) {
      print("Firestore'a kitap ekleme hatası: $e");
      // Hata yönetimi UI tarafında yapılabilir veya burada Exception fırlatılabilir
      throw Exception("Kitap eklenirken bir hata oluştu: $e");
    }
  }

  // Tüm Kitapları Getirme (Stream olarak - anlık güncellemeler için)
  // Şimdilik sadece takasa uygun olanları getirelim
  Stream<QuerySnapshot> getAvailableBooksStream() {
    // 'books' koleksiyonundaki 'isAvailable' alanı true olanları getir,
    // eklenme zamanına göre en yeniden eskiye doğru sırala.
    return _booksCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots(); // snapshots() metodu bir Stream döndürür
  }

  // Belirli Bir Kitabı Getirme (Future olarak - tek seferlik okuma)
  Future<DocumentSnapshot> getBookById(String bookId) async {
    try {
      DocumentSnapshot doc = await _booksCollection.doc(bookId).get();
      if (!doc.exists) {
        throw Exception("Kitap bulunamadı!");
      }
      return doc;
    } catch (e) {
      print("Kitap getirme hatası: $e");
      rethrow; // Hatayı tekrar fırlat ki çağıran yer haberdar olsun
    }
  }

  // TODO: Kitap Güncelleme (updateBook) fonksiyonu eklenebilir
  // TODO: Kitap Silme (deleteBook) fonksiyonu eklenebilir
  // TODO: Kullanıcının Kendi Kitaplarını Getirme fonksiyonu eklenebilir

  // --- Kullanıcı Profili İşlemleri ---
  // Kullanıcılar koleksiyonuna referans
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Kullanıcı profil verisini getirme
  Future<DocumentSnapshot?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print("Kullanıcı profili getirme hatası: $e");
      return null;
    }
  }

  // Kullanıcı profilini güncelleme
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
      print("Profil başarıyla güncellendi.");
    } catch (e) {
      print("Profil güncelleme hatası: $e");
      throw Exception("Profil güncellenirken bir hata oluştu: $e");
    }
  }

  // Not: Yeni kullanıcı kaydında profil oluşturma işlemi AuthService içinde yapılmıştı.
}
