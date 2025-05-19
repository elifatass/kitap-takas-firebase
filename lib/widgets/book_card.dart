import 'package:flutter/material.dart';
import '../models/book_model.dart'; // Oluşturduğumuz Book modelini import et

class BookCard extends StatelessWidget {
  final Book book; // Bu kartın göstereceği kitap verisi
  final VoidCallback?
  onTap; // Karta tıklandığında çalışacak fonksiyon (opsiyonel)

  const BookCard({Key? key, required this.book, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme; // Tema renkleri için
    final textTheme = Theme.of(context).textTheme; // Tema metin stilleri için

    return GestureDetector(
      // Tüm karta tıklama özelliği eklemek için
      onTap: onTap, // Eğer bir onTap fonksiyonu verildiyse onu çağır
      child: Card(
        elevation: 3, // Hafif bir gölge efekti
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Daha yuvarlak köşeler
        ),
        // Kartın dışına hafif bir margin ekleyerek daha ayrık durmasını sağlayabiliriz.
        // margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
                  top: Radius.circular(12),
                ), // Sadece üst köşeleri yuvarlat
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ); // Daha ince indicator
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              // Hata durumunda daha belirgin placeholder
                              color: Colors.grey.shade300,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.grey.shade600,
                                size: 40,
                              ),
                            );
                          },
                        )
                        : Container(
                          // Resim yoksa varsayılan bir ikon veya placeholder göster
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.menu_book,
                              color: Colors.grey.shade500,
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
                padding: const EdgeInsets.all(10.0), // Padding biraz artırıldı
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Yazıları sola yasla
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween, // İçerikleri dikeyde dağıt
                  children: [
                    Column(
                      // Başlık ve yazarı gruplamak için
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ), // Boyut ayarı
                          maxLines: 2, // En fazla 2 satır
                          overflow: TextOverflow.ellipsis, // Taşarsa ... koysun
                        ),
                        const SizedBox(height: 2), // Çok az boşluk
                        Text(
                          book.author,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                          ), // Boyut ayarı
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Takasa Uygunluk Etiketi
                    Align(
                      alignment: Alignment.centerRight,
                      child: Chip(
                        label: Text(
                          book.isAvailable ? 'Takasa Uygun' : 'Takasta Değil',
                          style: TextStyle(
                            fontSize: 10, // Font boyutu biraz küçültüldü
                            color:
                                book.isAvailable
                                    ? Colors.white
                                    : Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor:
                            book.isAvailable
                                ? colorScheme.primary
                                : Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 0,
                        ), // Daha küçük padding
                        materialTapTargetSize:
                            MaterialTapTargetSize
                                .shrinkWrap, // Tıklama alanını küçült
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                        ), // Label için padding
                        visualDensity:
                            VisualDensity.compact, // Daha kompakt görünüm
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
