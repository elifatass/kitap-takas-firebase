import 'dart:io'; // File tipi için
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ImageSource için
import 'package:kitap_takas_firebase/services/firestore_service.dart'; // Firestore servisi
import 'package:kitap_takas_firebase/services/image_picker_service.dart'; // Image Picker servisi
// TODO: Storage servisini import edeceğiz
// import 'package:kitap_takas_firebase/services/storage_service.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({Key? key}) : super(key: key);

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Servisleri başlatalım
  final ImagePickerService _imagePickerService = ImagePickerService();
  final FirestoreService _firestoreService = FirestoreService();
  // TODO: Storage servisini başlatalım
  // final StorageService _storageService = StorageService();

  // Seçilen resim dosyasını tutacak değişken
  File? _selectedImage;
  // Yükleme durumu
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Resim seçme fonksiyonu
  Future<void> _pickImage(ImageSource source) async {
    File? image = await _imagePickerService.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = image; // Seçilen resmi state'e ata
      });
    }
  }

  // Kitap ekleme fonksiyonu
  Future<void> _addBook() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form geçerli değilse çık
    }

    if (_selectedImage == null) {
      // Resim seçilmemişse uyarı ver (isteğe bağlı, resimsiz de eklenebilir)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kitap kapağı resmi seçin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Resmi Firebase Storage'a yükle (Bu fonksiyonu ekleyeceğiz)
      // String? imageUrl = await _storageService.uploadBookImage(_selectedImage!);
      // if (imageUrl == null) {
      //   throw Exception("Resim yüklenemedi.");
      // }
      // Şimdilik geçici URL kullanalım veya null bırakalım
      String? imageUrl = null; // <<-- Şimdilik null
      print("Resim yükleme adımı şimdilik atlandı.");

      // 2. Kitap bilgilerini Firestore'a kaydet
      await _firestoreService.addBook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl, // Yüklenen resmin URL'si veya null
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kitap başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Başarılı eklemeden sonra geri dön
      }
    } catch (e) {
      print("Kitap ekleme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kitap eklenirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Kitap Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Resim Seçme Alanı
              GestureDetector(
                onTap: () {
                  // Resim seçme seçeneklerini göster (örn: bottom sheet)
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => SafeArea(
                          // Alt çubukların arkasına geçmemesi için
                          child: Wrap(
                            // Seçenekleri yan yana sığdırmak için
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Galeriden Seç'),
                                onTap: () {
                                  _pickImage(ImageSource.gallery);
                                  Navigator.of(
                                    context,
                                  ).pop(); // Bottom sheet'i kapat
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_camera),
                                title: const Text('Kamera ile Çek'),
                                onTap: () {
                                  _pickImage(ImageSource.camera);
                                  Navigator.of(
                                    context,
                                  ).pop(); // Bottom sheet'i kapat
                                },
                              ),
                            ],
                          ),
                        ),
                  );
                },
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child:
                      _selectedImage != null
                          ? ClipRRect(
                            // Resmi yuvarlak köşeli göstermek için
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit:
                                  BoxFit
                                      .cover, // Resmi kaplayacak şekilde sığdır
                            ),
                          )
                          : const Center(
                            // Resim seçilmemişse
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text('Kapak Resmi Seçin'),
                              ],
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),

              // Kitap Başlığı
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Kitap Başlığı',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Başlık boş olamaz'
                            : null,
              ),
              const SizedBox(height: 15),

              // Yazar Adı
              TextFormField(
                controller: _authorController,
                decoration: InputDecoration(
                  labelText: 'Yazar Adı',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Yazar boş olamaz'
                            : null,
              ),
              const SizedBox(height: 15),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint:
                      true, // Çok satırlı için label'ı üste hizala
                ),
                maxLines: 4, // Daha fazla satır
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Açıklama boş olamaz'
                            : null,
              ),
              const SizedBox(height: 30),

              // Kitabı Ekle Butonu
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _addBook,
                icon:
                    _isLoading
                        ? Container(
                          // Dönen ikon için boyut belirle
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Icon(Icons.add_circle_outline),
                label: const Text('Kitabı Ekle'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
