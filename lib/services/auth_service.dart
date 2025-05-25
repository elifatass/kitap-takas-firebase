import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore importu

class AuthService {
  // Firebase Auth instance'ını alalım
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Firestore instance'ını alalım
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcıyı getir (veya null)
  User? get currentUser => _auth.currentUser;

  // Kullanıcı oturum durumu değişikliklerini dinlemek için Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // E-posta ve Şifre ile Giriş Yapma
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(
        "AuthService: signInWithEmailAndPassword Hatası: ${e.code} - ${e.message}",
      );
      return null;
    } catch (e) {
      print(
        "AuthService: signInWithEmailAndPassword içinde Beklenmedik Hata: $e",
      );
      return null;
    }
  }

  // E-posta ve Şifre ile Kayıt Olma (Firestore'a yazma ve detaylı loglama eklendi)
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    print(
      "AuthService: createUserWithEmailAndPassword çağrıldı - Email: $email",
    ); // BAŞLANGIÇ LOGU
    try {
      // 1. Önce kullanıcıyı Auth'da oluştur
      print("AuthService: Firebase Auth'da kullanıcı oluşturuluyor...");
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      print(
        "AuthService: Firebase Auth kullanıcısı başarıyla oluşturuldu. UID: ${userCredential.user?.uid}",
      );

      // 2. Kullanıcı başarıyla oluşturulduktan SONRA Firestore'a ekle
      if (userCredential.user != null) {
        print(
          "AuthService: Firestore'a kullanıcı verisi yazılacak. UID: ${userCredential.user!.uid}, Email: $email",
        );
        try {
          // 'users' koleksiyonuna yeni bir doküman ekle
          // Doküman ID'si olarak kullanıcının UID'sini kullan
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': email,
            'createdAt': Timestamp.now(), // Oluşturulma zamanını ekleyelim
            // TODO: 'username', 'bio', 'profilePicUrl' gibi alanlar eklenebilir
          });
          print(
            // BAŞARI LOGU
            "AuthService: Kullanıcı Firestore'a başarıyla eklendi: ${userCredential.user!.uid}",
          );
        } catch (firestoreError) {
          // FİRESTORE YAZMA HATASI
          print(
            "AuthService: Firestore'a yazma sırasında ÖNEMLİ HATA: $firestoreError",
          );
          print(
            "AuthService: Firestore Hatasının Tipi: ${firestoreError.runtimeType}",
          );
          // Hatanın detaylarını görmek için
          if (firestoreError is FirebaseException) {
            print("AuthService: Firestore Hata Kodu: ${firestoreError.code}");
            print(
              "AuthService: Firestore Hata Mesajı: ${firestoreError.message}",
            );
          }
          // Opsiyonel: Firestore hatası durumunda Auth kullanıcısını silmeyi düşünebilirsin
          // print("AuthService: Firestore hatası nedeniyle Auth kullanıcısı siliniyor...");
          // await userCredential.user?.delete();
          // print("AuthService: Auth kullanıcısı silindi.");
          // return null;
        }
      } else {
        print(
          "AuthService: Auth kullanıcısı oluşturuldu ama user nesnesi (userCredential.user) null geldi?",
        );
      }

      return userCredential; // Auth sonucunu döndür
    } on FirebaseAuthException catch (e) {
      // AUTH KAYIT HATASI
      print(
        "AuthService: FirebaseAuthException (Kayıt Hatası): ${e.code} - ${e.message}",
      );
      return null;
    } catch (e) {
      // DİĞER BEKLENMEDİK HATALAR
      print(
        "AuthService: createUserWithEmailAndPassword içinde Beklenmedik Hata: $e",
      );
      return null;
    }
  }

  // Çıkış Yapma
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("AuthService: Kullanıcı çıkış yaptı.");
    } catch (e) {
      print("AuthService: Çıkış Yapma Hatası: $e");
    }
  }

  // TODO: Şifre Sıfırlama, E-posta Doğrulama gibi diğer Auth metotları buraya eklenebilir.
}
