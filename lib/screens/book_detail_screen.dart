import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kitap_takas_firebase/models/book_model.dart';
import 'package:kitap_takas_firebase/services/firestore_service.dart';
// User? tipini kullanabilmek için firebase_auth importu gerekebilir
import 'package:firebase_auth/firebase_auth.dart'; // Kullanıcı bilgisini almak için

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  const BookDetailScreen({Key? key, required this.bookId}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Future<Book?>? _bookFuture;
  // Kitabı ekleyen kullanıcı bilgisini tutacak Future (DocumentSnapshot olarak)
  Future<DocumentSnapshot?>? _ownerProfileFuture;

  @override
  void initState() {
    super.initState();
    _bookFuture = _fetchBookDetails();
  }

  Future<Book?> _fetchBookDetails() async {
    try {
      DocumentSnapshot doc = await _firestoreService.getBookById(widget.bookId);
      if (doc.exists) {
        Book book = Book.fromFirestore(doc);
        // Kitap verisi çekildikten sonra, kitabı ekleyen kullanıcının profilini de çek
        if (mounted) {
          // State'in hala var olduğundan emin ol
          _fetchOwnerProfile(book.ownerId);
        }
        return book;
      } else {
        print("Kitap bulunamadı (ID: ${widget.bookId})");
        return null;
      }
    } catch (e) {
      print("Kitap detayı çekme hatası: $e");
      return null;
    }
  }

  // Kitabı ekleyen kullanıcının profilini çekme fonksiyonu
  void _fetchOwnerProfile(String ownerId) {
    // setState kullanarak _ownerProfileFuture'ı güncelliyoruz ki UI yenilensin
    if (mounted) {
      setState(() {
        _ownerProfileFuture = _firestoreService.getUserProfile(ownerId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kitap Detayı')),
      body: FutureBuilder<Book?>(
        future: _bookFuture,
        builder: (context, bookSnapshot) {
          // snapshot adını değiştirdim karışmasın diye
          if (bookSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (bookSnapshot.hasError ||
              !bookSnapshot.hasData ||
              bookSnapshot.data == null) {
            return Center(
              // ... (hata mesajı kısmı aynı) ...
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  bookSnapshot.hasError
                      ? 'Detaylar yüklenirken bir hata oluştu.\nLütfen daha sonra tekrar deneyin.'
                      : 'Bu kitap artık mevcut değil veya bulunamadı.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
              ),
            );
          }

          final Book book = bookSnapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kitap Kapağı Alanı (Aynı kaldı)
                Container(
                  height: 300,
                  color: Colors.grey.shade200,
                  child:
                      book.imageUrl != null && book.imageUrl!.isNotEmpty
                          ? Hero(
                            tag: 'bookImage_${book.id}',
                            child: Image.network(
                              book.imageUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          )
                          : const Center(
                            child: Icon(
                              Icons.menu_book,
                              size: 100,
                              color: Colors.grey,
                            ),
                          ),
                ),
                const SizedBox(height: 16),

                // Kitap Bilgileri
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yazan: ${book.author}',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        // Takasa uygunluk durumu (Aynı kaldı)
                        avatar: Icon(
                          book.isAvailable
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color:
                              book.isAvailable
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                          size: 18,
                        ),
                        label: Text(
                          book.isAvailable ? 'Takasa Uygun' : 'Takasta Değil',
                          style: TextStyle(
                            color:
                                book.isAvailable
                                    ? Colors.green.shade900
                                    : Colors.red.shade900,
                          ),
                        ),
                        backgroundColor:
                            book.isAvailable
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                        side: BorderSide.none,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'Açıklama',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.description.isNotEmpty
                            ? book.description
                            : 'Açıklama bulunmuyor.',
                        style: textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 20),

                      // --- Ekleyen Kullanıcı Bilgisi (YENİ EKLENDİ) ---
                      Text(
                        'Kitabı Ekleyen:',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<DocumentSnapshot?>(
                        future:
                            _ownerProfileFuture, // Sahip profilini çekmek için Future
                        builder: (context, ownerSnapshot) {
                          if (ownerSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              'Kullanıcı bilgisi yükleniyor...',
                            );
                          }
                          if (ownerSnapshot.hasError ||
                              !ownerSnapshot.hasData ||
                              ownerSnapshot.data == null) {
                            return const Text(
                              'Kullanıcı bilgisi bulunamadı.',
                              style: TextStyle(color: Colors.grey),
                            );
                          }
                          // Firestore'dan gelen kullanıcı verisini al
                          final ownerData =
                              ownerSnapshot.data!.data()
                                  as Map<String, dynamic>?;
                          final ownerEmail =
                              ownerData?['email'] as String? ?? 'Bilinmiyor';

                          return Row(
                            // İkon ve e-posta yan yana
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(ownerEmail, style: textTheme.bodyMedium),
                            ],
                          );
                        },
                      ),

                      // --- Ekleyen Kullanıcı Bilgisi SONU ---
                      const SizedBox(
                        height: 24,
                      ), // Buton için biraz daha boşluk
                      // Takas Teklif Et Butonu (Aynı kaldı)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              book.isAvailable
                                  ? () {
                                    print(
                                      "Takas teklif et butonuna basıldı: ${book.title}",
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Takas teklifi özelliği henüz hazır değil!',
                                        ),
                                      ),
                                    );
                                  }
                                  : null,
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Takas Teklif Et'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
