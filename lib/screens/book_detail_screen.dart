import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DocumentSnapshot için
import 'package:kitap_takas_firebase/models/book_model.dart'; // Book modeli
import 'package:kitap_takas_firebase/services/firestore_service.dart'; // Firestore servisi
import 'package:kitap_takas_firebase/services/auth_service.dart'; // AuthService'i import et

class BookDetailScreen extends StatefulWidget {
  final String bookId; // Detayları gösterilecek kitabın ID'si

  const BookDetailScreen({Key? key, required this.bookId}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService =
      AuthService(); // AuthService instance'ı eklendi
  Future<Book?>? _bookFuture;
  bool _isOffering = false; // Teklif gönderme sırasında yüklenme durumu için

  @override
  void initState() {
    super.initState();
    _bookFuture = _fetchBookDetails();
  }

  Future<Book?> _fetchBookDetails() async {
    try {
      DocumentSnapshot doc = await _firestoreService.getBookById(widget.bookId);
      if (doc.exists) {
        return Book.fromFirestore(doc);
      } else {
        print("Kitap bulunamadı (ID: ${widget.bookId})");
        return null;
      }
    } catch (e) {
      print("Kitap detayı çekme hatası: $e");
      return null;
    }
  }

  // Takas teklifi gönderme fonksiyonu
  Future<void> _handleOffer(Book offeredToBook) async {
    String? currentUserId = _authService.currentUser?.uid;

    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teklif yapmak için giriş yapmalısınız.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (currentUserId == offeredToBook.ownerId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kendi kitabınıza takas teklifi yapamazsınız.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isOffering = true; // Yükleniyor durumunu başlat
    });

    try {
      await _firestoreService.createOffer(
        targetBookId: offeredToBook.id,
        targetBookOwnerId: offeredToBook.ownerId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Takas teklifiniz başarıyla gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );
        // İsteğe bağlı: Tekliften sonra bir yere yönlendir veya pop-up kapat
        // Navigator.pop(context); // Geri dönebilir veya ana sayfaya gidebilir
      }
    } catch (e) {
      print("Takas teklifi hatası (UI): $e");
      String errorMessage = e.toString().replaceFirst(
        "Exception: ",
        "",
      ); // "Exception: " kısmını kaldır
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Teklif gönderilirken bir hata oluştu: $errorMessage',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOffering = false; // Yükleniyor durumunu bitir
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kitap Detayları')),
      body: FutureBuilder<Book?>(
        future: _bookFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                snapshot.hasError
                    ? 'Kitap yüklenirken bir hata oluştu: ${snapshot.error}'
                    : 'Kitap bulunamadı veya yüklenemedi.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final Book book = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kitap Resmi (Aynı kaldı)
                if (book.imageUrl != null && book.imageUrl!.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.network(
                        book.imageUrl!,
                        height: 250,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 250,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      height: 250,
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.menu_book,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Kitap Başlığı (Aynı kaldı)
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Yazar Adı (Aynı kaldı)
                Text(
                  'Yazar: ${book.author}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // Açıklama (Aynı kaldı)
                Text(
                  'Açıklama:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  book.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),

                // Takas Teklif Et Butonu (onPressed güncellendi)
                Center(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isOffering
                            ? null
                            : () =>
                                _handleOffer(book), // Yükleniyorsa tıklanamaz
                    icon:
                        _isOffering
                            ? Container(
                              // Yüklenme göstergesi
                              width: 20,
                              height: 20,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.swap_horiz),
                    label: Text(
                      _isOffering ? 'Gönderiliyor...' : 'Takas Teklif Et',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
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
