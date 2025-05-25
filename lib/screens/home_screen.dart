import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kitap_takas_firebase/services/auth_service.dart';
import 'package:kitap_takas_firebase/services/firestore_service.dart';
import 'package:kitap_takas_firebase/models/book_model.dart';
import 'package:kitap_takas_firebase/widgets/book_card.dart';
import 'book_detail_screen.dart';
import 'add_book_screen.dart';
import 'my_offers_screen.dart';
import 'my_sent_offers_screen.dart'; // MySentOffersScreen importu eklendi

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  void _signOut(BuildContext context) async {
    print("AppBar Çıkış Yap butonuna basıldı.");
    await _authService.signOut();
  }

  void _goToAddBookScreen(BuildContext context) {
    print("Kitap Ekle butonuna basıldı.");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBookScreen()),
    );
  }

  void _goToBookDetail(BuildContext context, String bookId) {
    print(
      "Kitap kartına tıklandı, ID: $bookId -> Detay ekranına yönlendiriliyor.",
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailScreen(bookId: bookId)),
    );
  }

  void _goToMyOffersScreen(BuildContext context) {
    // Gelen Teklifler
    print("Gelen Tekliflerim ikonuna basıldı.");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyOffersScreen()),
    );
  }

  // YENİ FONKSİYON: Gönderdiğim Teklifler ekranına git
  void _goToMySentOffersScreen(BuildContext context) {
    print("Gönderdiğim Teklifler ikonuna basıldı.");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MySentOffersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'KitapDünyası Takas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            tooltip: 'Ara',
            onPressed: () {
              print("Arama ikonuna basıldı.");
            },
          ),
          // Gelen Teklifler İkonu
          IconButton(
            icon: Icon(
              Icons.notifications_none_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Gelen Teklifler',
            onPressed: () => _goToMyOffersScreen(context),
          ),
          // YENİ İKON: Gönderdiğim Teklifler
          IconButton(
            icon: Icon(
              Icons.outbox_outlined,
              color: colorScheme.onSurfaceVariant,
            ), // Örnek ikon
            tooltip: 'Gönderdiğim Teklifler',
            onPressed: () => _goToMySentOffersScreen(context),
          ),
          IconButton(
            icon: Icon(
              Icons.account_circle_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Profilim',
            onPressed: () {
              print("Profil ikonuna basıldı.");
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.error),
            tooltip: 'Çıkış Yap',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Merhaba, ${_currentUser?.email?.split('@')[0] ?? 'Kitapsever'}!',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hangi kitabı takas etmek istersin?',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Kitap adı, yazar veya ISBN ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                print("Arama: $value");
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip(context, 'Roman', true),
                  _buildCategoryChip(context, 'Bilim Kurgu', false),
                  _buildCategoryChip(context, 'Tarih', false),
                  _buildCategoryChip(context, 'Çocuk Kitapları', false),
                  _buildCategoryChip(context, 'Eğitim', false),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Öne Çıkanlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getAvailableBooksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print("Firestore Stream Hatası: ${snapshot.error}");
                    return const Center(
                      child: Text('Kitaplar yüklenirken bir hata oluştu.'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Henüz takas edilecek kitap bulunmuyor.\nSağ alttaki (+) butonu ile kitap ekleyebilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                  final List<DocumentSnapshot> documents = snapshot.data!.docs;
                  return GridView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      final book = Book.fromFirestore(doc);
                      return BookCard(
                        book: book,
                        onTap: () => _goToBookDetail(context, book.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToAddBookScreen(context),
        tooltip: 'Yeni Kitap Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String label,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          print("Kategori seçildi: $label, Durum: $selected");
        },
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color:
              isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
