import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kitap_takas_firebase/models/book_model.dart';
import 'package:kitap_takas_firebase/services/firestore_service.dart';
import 'package:kitap_takas_firebase/services/auth_service.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;
  const BookDetailScreen({Key? key, required this.bookId}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  Future<Book?>? _bookFuture;
  bool _isOffering = false;
  String? _selectedMyBookIdForOffer;

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
      }
      return null;
    } catch (e) {
      print("Kitap detayı çekme hatası: $e");
      return null;
    }
  }

  Future<void> _showMyBooksDialog(Book offeredToBook) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Takas İçin Bir Kitap Seçin'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getAvailableBooksOfCurrentUserStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text(
                    'Kitaplarınız yüklenirken bir hata oluştu.',
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'Takas edebileceğiniz uygun bir kitabınız bulunmuyor.',
                  );
                }
                final List<DocumentSnapshot> myBookDocs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: myBookDocs.length,
                  itemBuilder: (context, index) {
                    final Book myBook = Book.fromFirestore(myBookDocs[index]);
                    if (myBook.id == offeredToBook.id) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      title: Text(myBook.title),
                      subtitle: Text(myBook.author),
                      onTap: () {
                        Navigator.of(context).pop(); // Önce diyaloğu kapat
                        // _selectedMyBookIdForOffer'ı burada atamaya gerek yok, direkt fonksiyona geçiyoruz
                        _handleOffer(
                          offeredToBook,
                          myBook.id,
                        ); // Seçilen kitabın ID'sini gönder
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleOffer(
    Book offeredToBook,
    String? offeredByMeBookId,
  ) async {
    String? currentUserId = _authService.currentUser?.uid;

    if (currentUserId == null) {
      if (mounted) {
        // DÜZELTİLDİ: ScaffoldMessenger
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
        // DÜZELTİLDİ: ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kendi kitabınıza takas teklifi yapamazsınız.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    if (offeredByMeBookId == null) {
      if (mounted) {
        // DÜZELTİLDİ: ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen takas için bir kitap seçin.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
      return;
    }

    setState(() {
      _isOffering = true;
    });

    try {
      await _firestoreService.createOffer(
        targetBookId: offeredToBook.id,
        targetBookOwnerId: offeredToBook.ownerId,
        offeredByMeBookId: offeredByMeBookId,
      );
      if (mounted) {
        // DÜZELTİLDİ: ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Takas teklifiniz başarıyla gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Takas teklifi hatası (UI): $e");
      String errorMessage = e.toString().replaceFirst("Exception: ", "");
      if (mounted) {
        // DÜZELTİLDİ: ScaffoldMessenger
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
          _isOffering = false;
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
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yazar: ${book.author}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
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
                Center(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isOffering ? null : () => _showMyBooksDialog(book),
                    icon:
                        _isOffering
                            ? Container(
                              width: 20,
                              height: 20,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.swap_horiz),
                    label: Text(
                      _isOffering ? 'Gönderiliyor...' : 'Takas İçin Kitap Seç',
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
