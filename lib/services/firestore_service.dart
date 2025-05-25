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

  // Tüm takasa uygun kitapları getir (Ana sayfa için)
  Stream<QuerySnapshot> getAvailableBooksStream() {
    return _booksCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // YENİ EKLENEN FONKSİYON: Mevcut kullanıcının takasa uygun kitaplarını getir
  Stream<QuerySnapshot> getAvailableBooksOfCurrentUserStream() {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.empty(); // Kullanıcı giriş yapmamışsa boş stream
    }
    // 'books' koleksiyonunda, 'ownerId' alanı mevcut kullanıcının UID'sine eşit olan
    // VE 'isAvailable' alanı true olan dokümanları getir,
    // oluşturulma zamanına göre en yeniden eskiye doğru sırala.
    return _booksCollection
        .where('ownerId', isEqualTo: currentUserId)
        .where('isAvailable', isEqualTo: true) // Sadece takasa uygun olanlar
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
    // ... (öncekiyle aynı) ...
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print("Kullanıcı profili getirme hatası: $e");
      return null;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    // ... (öncekiyle aynı) ...
    try {
      await _usersCollection.doc(uid).update(data);
      print("Profil başarıyla güncellendi.");
    } catch (e) {
      print("Profil güncelleme hatası: $e");
      throw Exception("Profil güncellenirken bir hata oluştu: $e");
    }
  }

  // --- Takas Teklif İşlemleri ---
  // createOffer fonksiyonuna teklif edilen kitap ID'si eklenecek (bir sonraki adımda)
  Future<void> createOffer({
    required String targetBookId,
    required String targetBookOwnerId,
    String?
    offeredByMeBookId, // YENİ: Teklif eden kişinin sunduğu kitabın ID'si
  }) async {
    String? offeringUserId = _auth.currentUser?.uid;
    if (offeringUserId == null)
      throw Exception("Teklif oluşturmak için kullanıcı girişi gerekli.");
    if (offeringUserId == targetBookOwnerId)
      throw Exception("Kendi kitabınıza takas teklifi yapamazsınız.");

    // offeredByMeBookId'nin null olmaması durumunu da kontrol edebiliriz (şimdilik opsiyonel)
    if (offeredByMeBookId == null) {
      throw Exception("Lütfen takas için bir kitap seçin.");
    }

    try {
      await _offersCollection.add({
        'offeringUserId': offeringUserId,
        'targetBookId': targetBookId,
        'targetBookOwnerId': targetBookOwnerId,
        'offeredByMeBookId': offeredByMeBookId, // YENİ ALAN EKLENDİ
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
      print("Takas teklifi başarıyla oluşturuldu (karşılıklı kitap ile).");
    } catch (e) {
      print("Takas teklifi oluşturma hatası: $e");
      throw Exception("Takas teklifi gönderilirken bir hata oluştu: $e");
    }
  }

  // Kullanıcıya GELEN bekleyen teklifleri getir
  Stream<QuerySnapshot> getPendingOffersForUserStream() {
    // ... (öncekiyle aynı) ...
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.empty();
    return _offersCollection
        .where('targetBookOwnerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Teklifi Kabul Etme
  Future<void> acceptOffer(
    String offerId,
    String targetBookId,
    String? offeredByMeBookIdIfAny,
  ) async {
    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference offerRef = _offersCollection.doc(offerId);
      batch.update(offerRef, {'status': 'accepted'});

      // Teklif yapılan (hedef) kitabın durumu 'false' yapılıyor
      DocumentReference targetBookRef = _booksCollection.doc(targetBookId);
      batch.update(targetBookRef, {'isAvailable': false});

      // Eğer teklif eden de bir kitap sunduysa (offeredByMeBookIdIfAny null değilse),
      // o kitabın da durumunu 'false' yap
      if (offeredByMeBookIdIfAny != null) {
        DocumentReference offeredByMeBookRef = _booksCollection.doc(
          offeredByMeBookIdIfAny,
        );
        batch.update(offeredByMeBookRef, {'isAvailable': false});
        print(
          "Karşılık teklif edilen kitap ($offeredByMeBookIdIfAny) da takasta değil olarak işaretlendi.",
        );
      }

      await batch.commit();
      print(
        "Teklif ($offerId) kabul edildi ve ilgili kitap(lar)ın durumu güncellendi.",
      );
    } catch (e) {
      print("Teklif kabul etme hatası: $e");
      throw Exception("Teklif kabul edilirken bir hata oluştu: $e");
    }
  }

  // Teklifi Reddetme
  Future<void> rejectOffer(String offerId) async {
    // ... (öncekiyle aynı) ...
    try {
      await _offersCollection.doc(offerId).update({'status': 'rejected'});
      print("Teklif ($offerId) reddedildi.");
    } catch (e) {
      print("Teklif reddetme hatası: $e");
      throw Exception("Teklif reddedilirken bir hata oluştu: $e");
    }
  }

  // Kullanıcının YAPTIĞI teklifleri getir (tüm durumlar)
  Stream<QuerySnapshot> getOffersMadeByUserStream() {
    // ... (öncekiyle aynı) ...
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.empty();
    return _offersCollection
        .where('offeringUserId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
