// lib/core/models/bid_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Bid extends Equatable {
  final String userId;
  final double amount;
  final Timestamp timestamp;

  const Bid({
    required this.userId,
    required this.amount,
    required this.timestamp,
  });

  factory Bid.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return Bid(
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
  
  @override
  List<Object?> get props => [userId, amount, timestamp];
}