import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String id; // Firestore doküman ID'si
  final String offeringUserId;
  final String targetBookId;
  final String targetBookOwnerId;
  final String status; // 'pending', 'accepted', 'rejected'
  final Timestamp createdAt;
  final String?
  offeredByMeBookId; // YENİ ALAN EKLENDİ VE CONSTRUCTOR/FROMFIRESTORE'A DAHİL EDİLDİ

  Offer({
    required this.id,
    required this.offeringUserId,
    required this.targetBookId,
    required this.targetBookOwnerId,
    required this.status,
    required this.createdAt,
    this.offeredByMeBookId, // Constructor'a eklendi
  });

  factory Offer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Offer(
      id: doc.id,
      offeringUserId: data['offeringUserId'] ?? '',
      targetBookId: data['targetBookId'] ?? '',
      targetBookOwnerId: data['targetBookOwnerId'] ?? '',
      status: data['status'] ?? 'unknown',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      offeredByMeBookId:
          data['offeredByMeBookId'] as String?, // Firestore'dan oku
    );
  }

  // Firestore'a yazmak için Map (Eğer FirestoreService dışında kullanılacaksa)
  Map<String, dynamic> toFirestore() {
    return {
      'offeringUserId': offeringUserId,
      'targetBookId': targetBookId,
      'targetBookOwnerId': targetBookOwnerId,
      'status': status,
      'createdAt': createdAt,
      if (offeredByMeBookId != null)
        'offeredByMeBookId': offeredByMeBookId, // Sadece null değilse ekle
    };
  }
}
