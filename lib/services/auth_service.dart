import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Firebase Auth instance'ını alalım
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mevcut kullanıcıyı getir (veya null)
  User? get currentUser => _auth.currentUser;

  // Kullanıcı oturum durumu değişikliklerini dinlemek için Stream
  // Bu, kullanıcının giriş yapıp yapmadığını veya çıkış yaptığını anlık olarak takip etmemizi sağlar.
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
      // Hata durumunda null döndürebilir veya hatayı tekrar fırlatabiliriz.
      // Şimdilik hatayı yazdırıp null döndürelim, UI tarafında yönetiriz.
      print("Giriş Hatası (AuthService): ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Beklenmedik Giriş Hatası (AuthService): $e");
      return null;
    }
  }

  // E-posta ve Şifre ile Kayıt Olma
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
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
      // Çıkış yapma hatası genellikle kritik değildir,
      // ama yine de loglamak iyi bir fikirdir.
    }
  }

  // TODO: Şifre Sıfırlama, E-posta Doğrulama gibi diğer Auth metotları buraya eklenebilir.
}
