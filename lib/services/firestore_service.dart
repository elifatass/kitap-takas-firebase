import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Kullanıcı UID'si için

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final CollectionReference _booksCollection = FirebaseFirestore.instance
      .collection('books');
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference _offersCollection = FirebaseFirestore.instance
      .collection('offers');

  // --- Kitap İşlemleri ---
  Future<void> addBook({
    required String title,
    required String author,
    required String description,
    String? imageUrl,
    String? category,
  }) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("Kullanıcı girişi yapılmamış.");
      await _booksCollection.add({
        'title': title,
        'author': author,
        'description': description,
        'imageUrl': imageUrl,
        'ownerId': userId,
        'createdAt': Timestamp.now(),
        'isAvailable': true,
        'category': category,
      });
      print("Kitap (kategori ile) başarıyla Firestore'a eklendi.");
    } catch (e) {
      print("Firestore'a kitap ekleme hatası: $e");
      throw Exception("Kitap eklenirken bir hata oluştu: $e");
    }
  }

  Stream<QuerySnapshot> getAvailableBooksStream() {
    return _booksCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getBookById(String bookId) async {
    try {
      DocumentSnapshot doc = await _booksCollection.doc(bookId).get();
      if (!doc.exists) throw Exception("Kitap bulunamadı!");
      return doc;
    } catch (e) {
      print("Kitap getirme hatası: $e");
      rethrow;
    }
  }

  // --- Kullanıcı Profili İşlemleri ---
  Future<DocumentSnapshot?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print("Kullanıcı profili getirme hatası: $e");
      return null;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
      print("Profil başarıyla güncellendi.");
    } catch (e) {
      print("Profil güncelleme hatası: $e");
      throw Exception("Profil güncellenirken bir hata oluştu: $e");
    }
  }

  // --- Takas Teklif İşlemleri ---
  Future<void> createOffer({
    required String targetBookId,
    required String targetBookOwnerId,
  }) async {
    String? offeringUserId = _auth.currentUser?.uid;
    if (offeringUserId == null)
      throw Exception("Teklif oluşturmak için kullanıcı girişi gerekli.");
    if (offeringUserId == targetBookOwnerId)
      throw Exception("Kendi kitabınıza takas teklifi yapamazsınız.");
    try {
      await _offersCollection.add({
        'offeringUserId': offeringUserId,
        'targetBookId': targetBookId,
        'targetBookOwnerId': targetBookOwnerId,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
      print("Takas teklifi başarıyla oluşturuldu.");
    } catch (e) {
      print("Takas teklifi oluşturma hatası: $e");
      throw Exception("Takas teklifi gönderilirken bir hata oluştu: $e");
    }
  }

  // Kullanıcıya GELEN bekleyen teklifleri getir
  Stream<QuerySnapshot> getPendingOffersForUserStream() {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.empty();
    return _offersCollection
        .where('targetBookOwnerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Teklifi Kabul Etme
  Future<void> acceptOffer(String offerId, String offeredBookId) async {
    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference offerRef = _offersCollection.doc(offerId);
      batch.update(offerRef, {'status': 'accepted'});
      DocumentReference bookRef = _booksCollection.doc(offeredBookId);
      batch.update(bookRef, {'isAvailable': false});
      await batch.commit();
      print(
        "Teklif ($offerId) kabul edildi ve kitap ($offeredBookId) durumu güncellendi.",
      );
    } catch (e) {
      print("Teklif kabul etme hatası: $e");
      throw Exception("Teklif kabul edilirken bir hata oluştu: $e");
    }
  }

  // Teklifi Reddetme
  Future<void> rejectOffer(String offerId) async {
    try {
      await _offersCollection.doc(offerId).update({'status': 'rejected'});
      print("Teklif ($offerId) reddedildi.");
    } catch (e) {
      print("Teklif reddetme hatası: $e");
      throw Exception("Teklif reddedilirken bir hata oluştu: $e");
    }
  }

  // YENİ EKLENEN FONKSİYON: Kullanıcının YAPTIĞI teklifleri getir (tüm durumlar)
  Stream<QuerySnapshot> getOffersMadeByUserStream() {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.empty(); // Kullanıcı giriş yapmamışsa boş stream
    }
    // 'offers' koleksiyonunda, 'offeringUserId' alanı mevcut kullanıcının UID'sine eşit olan
    // tüm dokümanları getir, oluşturulma zamanına göre en yeniden eskiye doğru sırala.
    return _offersCollection
        .where('offeringUserId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // TODO: Teklif durumunu güncelleme (kabul/ret) fonksiyonu eklenecek (aslında accept ve reject olarak eklendi)
}
