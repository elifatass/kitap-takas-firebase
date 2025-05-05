import 'dart:io'; // File tipi için
import 'package:firebase_storage/firebase_storage.dart'; // Eklediğimiz paket
import 'package:firebase_auth/firebase_auth.dart'; // Kullanıcı ID'si için
import 'package:path/path.dart' as path; // Dosya uzantısını almak için

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kitap resmini yükleme ve indirme URL'sini alma
  Future<String?> uploadBookImage(File imageFile) async {
    try {
      // Giriş yapmış kullanıcının UID'sini al (klasörleme için)
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("Resim yüklemek için kullanıcı girişi gerekli.");
      }

      // Benzersiz bir dosya adı oluştur (örn: userId_timestamp.jpg)
      // Dosya uzantısını alalım (.jpg, .png vb.)
      String fileExtension = path.extension(imageFile.path);
      // Zaman damgası ve rastgelelikle benzersizliği artıralım
      String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}${fileExtension}';

      // Yükleme yolunu belirle (örn: book_images/userId/dosyaAdi.jpg)
      // Kullanıcıya özel klasör oluşturmak iyi bir pratiktir.
      Reference storageRef = _storage.ref().child(
        'book_images/$userId/$fileName',
      );

      print('Resim yükleniyor: ${storageRef.fullPath}');

      // Dosyayı Storage'a yükle
      UploadTask uploadTask = storageRef.putFile(imageFile);

      // Yükleme tamamlanana kadar bekle
      TaskSnapshot snapshot = await uploadTask;

      // Yükleme başarılıysa indirme URL'sini al
      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        print('Resim başarıyla yüklendi. URL: $downloadUrl');
        return downloadUrl;
      } else {
        print('Resim yükleme başarısız. Durum: ${snapshot.state}');
        return null;
      }
    } on FirebaseException catch (e) {
      print('Firebase Storage Hatası: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Beklenmedik Storage Hatası: $e');
      return null;
    }
  }

  // TODO: Profil resmi yükleme fonksiyonu eklenebilir
  // TODO: Dosya silme fonksiyonu eklenebilir
}
