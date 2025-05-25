import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kitap_takas_firebase/services/firestore_service.dart';
import 'package:kitap_takas_firebase/models/offer_model.dart';
import 'package:kitap_takas_firebase/models/book_model.dart';
// UserModel'i henüz oluşturmadık ama e-postayı direkt users koleksiyonundan çekebiliriz.

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({Key? key}) : super(key: key);

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _processingOfferId;
  bool _isProcessing = false;

  Future<void> _acceptOffer(String offerId, String targetBookId) async {
    setState(() {
      _isProcessing = true;
      _processingOfferId = offerId;
    });
    try {
      await _firestoreService.acceptOffer(offerId, targetBookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teklif başarıyla kabul edildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Teklif kabul edilirken hata oluştu: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingOfferId = null;
        });
      }
    }
  }

  Future<void> _rejectOffer(String offerId) async {
    setState(() {
      _isProcessing = true;
      _processingOfferId = offerId;
    });
    try {
      await _firestoreService.rejectOffer(offerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teklif reddedildi.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Teklif reddedilirken hata oluştu: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingOfferId = null;
        });
      }
    }
  }

  Widget _buildBookTitle(String bookId) {
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
          'Teklif: "${book.title}" için',
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
      },
    );
  }

  // YENİ YARDIMCI WIDGET: Teklifi yapan kullanıcının e-postasını getirir
  Widget _buildOfferingUserEmail(String userId) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _firestoreService.getUserProfile(
        userId,
      ), // Kullanıcı profilini UID ile çek
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            "Teklif eden yükleniyor...",
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          );
        }
        if (userSnapshot.hasError ||
            !userSnapshot.hasData ||
            userSnapshot.data == null ||
            !userSnapshot.data!.exists) {
          return const Text(
            "Teklif eden bulunamadı",
            style: TextStyle(color: Colors.red, fontSize: 12),
          );
        }
        // users koleksiyonundaki dokümandan email alanını al
        final Map<String, dynamic>? userData =
            userSnapshot.data!.data() as Map<String, dynamic>?;
        final String userEmail = userData?['email'] ?? 'Bilinmeyen E-posta';
        return Text(
          userEmail,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gelen Takas Teklifleri')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getPendingOffersForUserStream(),
        builder: (context, snapshot) {
          // ... (Yükleniyor, Hata, Boş Liste durumları aynı kaldı) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Gelen Teklifler Stream Hatası: ${snapshot.error}");
            return const Center(
              child: Text('Teklifler yüklenirken bir hata oluştu.'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Henüz bekleyen bir takas teklifiniz bulunmuyor.',
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
              bool currentOfferIsProcessing =
                  _isProcessing && _processingOfferId == offer.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: _buildBookTitle(offer.targetBookId),
                  subtitle: Column(
                    // Subtitle'ı Column içine aldık
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 4,
                      ), // Başlık ile arasında biraz boşluk
                      Row(
                        children: [
                          const Text(
                            "Teklif Eden: ",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: _buildOfferingUserEmail(
                              offer.offeringUserId,
                            ),
                          ), // Kullanıcı e-postasını göster
                        ],
                      ),
                      Text(
                        'Tarih: $formattedDate',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true, // Yüksekliği ayarlar
                  trailing:
                      currentOfferIsProcessing
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                tooltip: 'Kabul Et',
                                onPressed:
                                    _isProcessing
                                        ? null
                                        : () => _acceptOffer(
                                          offer.id,
                                          offer.targetBookId,
                                        ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                tooltip: 'Reddet',
                                onPressed:
                                    _isProcessing
                                        ? null
                                        : () => _rejectOffer(offer.id),
                              ),
                            ],
                          ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
