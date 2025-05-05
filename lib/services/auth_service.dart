import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore importu eklendi

class AuthService {
  // Firebase Auth instance'ını alalım
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Firestore instance'ını alalım
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore eklendi

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
      print("Giriş Hatası (AuthService): ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Beklenmedik Giriş Hatası (AuthService): $e");
      return null;
    }
  }

  // E-posta ve Şifre ile Kayıt Olma (Firestore'a yazma eklendi)
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // 1. Önce kullanıcıyı Auth'da oluştur
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Kullanıcı başarıyla oluşturulduktan SONRA Firestore'a ekle
      if (userCredential.user != null) {
        print("Auth kullanıcısı oluşturuldu, Firestore'a yazılıyor...");
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
            "Kullanıcı Firestore'a başarıyla eklendi: ${userCredential.user!.uid}",
          );
        } catch (firestoreError) {
          print("Firestore'a yazma hatası: $firestoreError");
          // Opsiyonel: Firestore hatası durumunda Auth kullanıcısını silmeyi düşünebilirsin
          // await userCredential.user?.delete();
          // return null; // veya hatayı tekrar fırlat
        }
      } else {
        print("Auth kullanıcısı oluşturuldu ama user nesnesi null geldi?");
      }

      return userCredential; // Auth sonucunu döndür
    } on FirebaseAuthException catch (e) {
      print("Kayıt Hatası (AuthService): ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Beklenmedik Kayıt Hatası (AuthService): $e");
      return null;
    }
  }

  // Çıkış Yapma
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Çıkış Yapma Hatası (AuthService): $e");
    }
  }

  // TODO: Şifre Sıfırlama, E-posta Doğrulama gibi diğer Auth metotları buraya eklenebilir.
}
