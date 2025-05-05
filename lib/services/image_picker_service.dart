import 'dart:io'; // File nesnesini kullanmak için
import 'package:image_picker/image_picker.dart'; // Eklediğimiz paket

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  // Galeriden veya kameradan resim seçme fonksiyonu
  // source parametresi ile kaynağı belirteceğiz (gallery veya camera)
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      // image_picker paketini kullanarak resmi seç/çek
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality:
            80, // Resim kalitesini biraz düşürelim (opsiyonel, dosya boyutunu küçültür)
        maxWidth:
            1080, // Maksimum genişlik (opsiyonel, dosya boyutunu küçültür)
      );

      // Kullanıcı resim seçmekten vazgeçerse veya hata olursa pickedFile null olabilir
      if (pickedFile != null) {
        // Seçilen resmin yolunu (path) kullanarak bir File nesnesi oluşturup döndür
        return File(pickedFile.path);
      } else {
        print('Resim seçilmedi.');
        return null; // Resim seçilmediyse null döndür
      }
    } catch (e) {
      print('Resim seçme hatası: $e');
      return null; // Hata durumunda null döndür
    }
  }

  // Sadece galeriden seçmek için kısayol fonksiyonu (isteğe bağlı)
  Future<File?> pickImageFromGallery() async {
    return await pickImage(source: ImageSource.gallery);
  }

  // Sadece kameradan çekmek için kısayol fonksiyonu (isteğe bağlı)
  Future<File?> pickImageFromCamera() async {
    return await pickImage(source: ImageSource.camera);
  }
}
