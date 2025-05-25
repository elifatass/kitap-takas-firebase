import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kitap_takas_firebase/services/firestore_service.dart';
import 'package:kitap_takas_firebase/models/offer_model.dart';
import 'package:kitap_takas_firebase/models/book_model.dart'; // Kitap başlığı için hala gerekli olabilir

class MySentOffersScreen extends StatefulWidget {
  // SINIF ADI DEĞİŞTİ
  const MySentOffersScreen({Key? key}) : super(key: key);

  @override
  State<MySentOffersScreen> createState() => _MySentOffersScreenState(); // STATE ADI DEĞİŞTİ
}

class _MySentOffersScreenState extends State<MySentOffersScreen> {
  // STATE ADI DEĞİŞTİ
  final FirestoreService _firestoreService = FirestoreService();

  // Kitap başlığını getirmek için yardımcı bir widget (MyOffersScreen'den alabiliriz)
  // Bu, teklif yapılan kitabın adını göstermek için kullanılacak.
  Widget _buildTargetBookTitle(String bookId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestoreService.getBookById(bookId),
      builder: (context, bookSnapshot) {
        if (bookSnapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            "Kitap adı yükleniyor...",
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
          );
        }
        if (bookSnapshot.hasError ||
            !bookSnapshot.hasData ||
            !bookSnapshot.data!.exists) {
          return const Text(
            "Kitap adı bulunamadı",
            style: TextStyle(color: Colors.red, fontSize: 14),
          );
        }
        final Book book = Book.fromFirestore(bookSnapshot.data!);
        return Text(
          '"${book.title}" kitabına teklif', // Değiştirilmiş başlık
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  // TODO: İleride "Teklifi İptal Et" fonksiyonu buraya eklenebilir
  // Future<void> _cancelOffer(String offerId) async { ... }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gönderdiğim Teklifler'), // APPBAR BAŞLIĞI DEĞİŞTİ
      ),
      body: StreamBuilder<QuerySnapshot>(
        // BURASI ÇOK ÖNEMLİ: FirestoreService'te bu fonksiyonu oluşturacağız
        stream:
            _firestoreService
                .getOffersMadeByUserStream(), // STREAM DEĞİŞTİ (HATA VERECEK)
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print(
              "Gönderdiğim Teklifler Stream Hatası: ${snapshot.error}",
            ); // Log mesajı güncellendi
            return const Center(
              child: Text('Teklifleriniz yüklenirken bir hata oluştu.'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Henüz gönderilmiş bir takas teklifiniz bulunmuyor.', // Mesaj güncellendi
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final List<DocumentSnapshot> offerDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: offerDocs.length,
            itemBuilder: (context, index) {
              final Offer offer = Offer.fromFirestore(offerDocs[index]);
              final Timestamp createdAtTimestamp = offer.createdAt;
              final DateTime createdAtDate = createdAtTimestamp.toDate();
              final String formattedDate =
                  "${createdAtDate.day}.${createdAtDate.month}.${createdAtDate.year}";

              Color statusColor = Colors.grey;
              String statusText = offer.status.toUpperCase();
              if (offer.status == 'pending') {
                statusColor = Colors.orangeAccent;
                statusText = 'BEKLEMEDE';
              } else if (offer.status == 'accepted') {
                statusColor = Colors.green;
                statusText = 'KABUL EDİLDİ';
              } else if (offer.status == 'rejected') {
                statusColor = Colors.red;
                statusText = 'REDDEDİLDİ';
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: _buildTargetBookTitle(
                    offer.targetBookId,
                  ), // Teklif yapılan kitabın adını göster
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Durum: $statusText',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Tarih: $formattedDate',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      // TODO: Teklif yapılan kitabın sahibinin e-postasını/adını gösterebiliriz.
                      // Text('Kitap Sahibi ID: ${offer.targetBookOwnerId}'),
                    ],
                  ),
                  isThreeLine: true, // Yüksekliği ayarlar
                  // Bu ekranda Kabul/Reddet butonu olmaz.
                  // Belki "Teklifi Geri Çek" butonu eklenebilir (eğer status 'pending' ise)
                  // trailing: offer.status == 'pending'
                  //     ? TextButton(
                  //         onPressed: () {
                  //           // TODO: _cancelOffer(offer.id);
                  //           print("Teklifi iptal et basıldı: ${offer.id}");
                  //         },
                  //         child: Text("İptal Et", style: TextStyle(color: Colors.redAccent)),
                  //       )
                  //     : null, // Diğer durumlarda trailing'de bir şey gösterme
                ),
              );
            },
          );
        },
      ),
    );
  }
}
