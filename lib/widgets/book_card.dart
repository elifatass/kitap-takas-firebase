import 'package:flutter/material.dart';
import '../models/book_model.dart'; // Oluşturduğumuz Book modelini import et

class BookCard extends StatelessWidget {
  final Book book; // Bu kartın göstereceği kitap verisi
  final VoidCallback?
  onTap; // Karta tıklandığında çalışacak fonksiyon (opsiyonel)

  const BookCard({Key? key, required this.book, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tüm karta tıklama özelliği eklemek için
      onTap: onTap, // Eğer bir onTap fonksiyonu verildiyse onu çağır
      child: Card(
        elevation: 3, // Hafif bir gölge efekti
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Yumuşak köşeler
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // İçerikleri genişlet
          children: [
            // Kitap Resmi Alanı
            Expanded(
              // Resmin kartın üst kısmını kaplaması için
              flex: 3, // Yüksekliğin çoğunu resme verelim (oran)
              child: ClipRRect(
                // Resmi kartın köşeleriyle uyumlu kesmek için
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child:
                    book.imageUrl != null && book.imageUrl!.isNotEmpty
                        ? Image.network(
                          // Eğer resim URL'si varsa göster
                          book.imageUrl!,
                          fit: BoxFit.cover, // Resmi alana sığdır ve kapla
                          // Yüklenirken veya hata durumunda gösterilecek widget'lar
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 40,
                              ),
                            );
                          },
                        )
                        : Container(
                          // Resim yoksa varsayılan bir ikon veya placeholder göster
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.menu_book,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                        ),
              ),
            ),

            // Kitap Bilgileri Alanı
            Expanded(
              // Kalan alanı bilgilere verelim
              flex: 2, // Resimden biraz daha az yer kaplasın (oran)
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Yazıları sola yasla
                  children: [
                    // Kitap Başlığı
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Grid için biraz daha küçük font
                      ),
                      maxLines: 2, // En fazla 2 satır
                      overflow: TextOverflow.ellipsis, // Taşarsa ... koysun
                    ),
                    const SizedBox(height: 4),

                    // Yazar Adı
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // TODO: Belki buraya yıldız (rating) veya fiyat gibi ek bilgiler eklenebilir
                    const Spacer(), // Kalan boşluğu doldurarak aşağıdaki butonu en alta iter
                    // Takas Et veya Detay Butonu (Örnek)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onTap, // Yine onTap'ı kullanalım
                        child: const Text('Detaylar'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
