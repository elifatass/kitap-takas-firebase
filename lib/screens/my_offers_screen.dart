import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kitap_takas_firebase/services/firestore_service.dart';
import 'package:kitap_takas_firebase/models/offer_model.dart';
import 'package:kitap_takas_firebase/models/book_model.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({Key? key}) : super(key: key);

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _processingOfferId;
  bool _isProcessing = false;

  Future<void> _acceptOffer(Offer offer) async {
    setState(() {
      _isProcessing = true;
      _processingOfferId = offer.id;
    });
    try {
      await _firestoreService.acceptOffer(
        offer.id,
        offer.targetBookId,
        offer.offeredByMeBookId,
      );
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

  Widget _buildBookInfoText(String bookId, String prefixText) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestoreService.getBookById(bookId),
      builder: (context, bookSnapshot) {
        if (bookSnapshot.connectionState == ConnectionState.waiting) {
          return Text(
            "$prefixText Kitap adı yükleniyor...",
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
          );
        }
        if (bookSnapshot.hasError ||
            !bookSnapshot.hasData ||
            !bookSnapshot.data!.exists) {
          return Text(
            "$prefixText Kitap adı bulunamadı",
            style: const TextStyle(color: Colors.red, fontSize: 13),
          );
        }
        final Book book = Book.fromFirestore(bookSnapshot.data!);
        return Text(
          '$prefixText "${book.title}"',
          style: const TextStyle(fontSize: 13),
        );
      },
    );
  }

  Widget _buildOfferingUserEmail(String userId) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _firestoreService.getUserProfile(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            "Teklif eden yükleniyor...",
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
          );
        }
        if (userSnapshot.hasError ||
            !userSnapshot.hasData ||
            userSnapshot.data == null ||
            !userSnapshot.data!.exists) {
          return const Text(
            "Teklif eden bulunamadı",
            style: TextStyle(color: Colors.red, fontSize: 13),
          );
        }
        final Map<String, dynamic>? userData =
            userSnapshot.data!.data() as Map<String, dynamic>?;
        final String userEmail = userData?['email'] ?? 'Bilinmeyen E-posta';
        return Text(
          userEmail,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
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

              // Karşılığında teklif edilen kitap için widget'ı burada oluşturalım
              Widget offeredByMeBookWidget;
              if (offer.offeredByMeBookId != null &&
                  offer.offeredByMeBookId!.isNotEmpty) {
                offeredByMeBookWidget = _buildBookInfoText(
                  offer.offeredByMeBookId!,
                  'Karşılığında Teklif Edilen:',
                );
              } else {
                offeredByMeBookWidget = const Text(
                  'Karşılığında doğrudan bir kitap teklif edilmedi.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                );
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildOfferingUserEmail(
                              offer.offeringUserId,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildBookInfoText(
                        offer.targetBookId,
                        'İstenilen Kitap:',
                      ),
                      const SizedBox(height: 6),
                      offeredByMeBookWidget, // Oluşturduğumuz widget'ı buraya koyuyoruz
                      const SizedBox(height: 10),
                      if (!currentOfferIsProcessing)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.redAccent,
                              ),
                              label: const Text(
                                'Reddet',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                              onPressed:
                                  _isProcessing
                                      ? null
                                      : () => _rejectOffer(offer.id),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Kabul Et'),
                              onPressed:
                                  _isProcessing
                                      ? null
                                      : () => _acceptOffer(offer),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
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
