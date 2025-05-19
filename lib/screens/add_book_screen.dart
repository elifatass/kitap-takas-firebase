import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kitap_takas_firebase/services/firestore_service.dart';

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

  final FirestoreService _firestoreService = FirestoreService();

  File? _selectedImage;
  bool _isLoading = false;

  // Kategoriler için bir liste ve seçilen kategoriyi tutacak değişken
  final List<String> _categories = [
    'Roman',
    'Bilim Kurgu',
    'Fantastik',
    'Tarih',
    'Biyografi',
    'Çocuk Kitapları',
    'Eğitim',
    'Kişisel Gelişim',
    'Şiir',
    'Diğer',
  ];
  String? _selectedCategory; // Başlangıçta null

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageXFile = await picker.pickImage(source: source);

    if (imageXFile != null) {
      setState(() {
        _selectedImage = File(imageXFile.path);
      });
    } else {
      print("Resim seçilmedi (AddBookScreen)");
    }
  }

  Future<void> _addBook() async {
    // Formun geçerli olup olmadığını kontrol et (Kategori de dahil)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = null; // Resim yükleme şimdilik atlanıyor

      await _firestoreService.addBook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        category: _selectedCategory, // SEÇİLEN KATEGORİYİ GÖNDER
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kitap (kategorili, resimsiz) başarıyla eklendi!',
            ), // Mesaj güncellendi
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
              // Resim Seçme Alanı (Aynı kaldı)
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => SafeArea(
                          child: Wrap(
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Galeriden Seç'),
                                onTap: () {
                                  _pickImage(ImageSource.gallery);
                                  Navigator.of(context).pop();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_camera),
                                title: const Text('Kamera ile Çek'),
                                onTap: () {
                                  _pickImage(ImageSource.camera);
                                  Navigator.of(context).pop();
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
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text('Kapak Resmi Seç (Opsiyonel)'),
                              ],
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                // Başlık (Aynı kaldı)
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

              TextFormField(
                // Yazar (Aynı kaldı)
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

              TextFormField(
                // Açıklama (Aynı kaldı)
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Açıklama boş olamaz'
                            : null,
              ),
              const SizedBox(height: 15), // Açıklama ve Kategori arası boşluk
              // KATEGORİ SEÇİMİ DROPDOWN (YENİ EKLENDİ)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: _selectedCategory,
                hint: const Text('Bir kategori seçin'),
                isExpanded: true,
                items:
                    _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator:
                    (value) =>
                        value == null
                            ? 'Lütfen bir kategori seçin'
                            : null, // Zorunlu alan
              ),

              // KATEGORİ SEÇİMİ DROPDOWN SONU
              const SizedBox(height: 30), // Kategori ve Buton arası boşluk

              ElevatedButton.icon(
                // Kitabı Ekle Butonu (Aynı kaldı)
                onPressed: _isLoading ? null : _addBook,
                icon:
                    _isLoading
                        ? Container(
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
