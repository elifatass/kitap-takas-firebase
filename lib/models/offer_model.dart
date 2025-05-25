import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String id; // Firestore doküman ID'si
  final String offeringUserId;
  final String targetBookId;
  final String targetBookOwnerId;
  final String status; // 'pending', 'accepted', 'rejected'
  final Timestamp createdAt;
  // İleride eklenecekler:
  // final List<String>? offeredBookIds;
  // final String? message;

  Offer({
    required this.id,
    required this.offeringUserId,
    required this.targetBookId,
    required this.targetBookOwnerId,
    required this.status,
    required this.createdAt,
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
    );
  }
}
