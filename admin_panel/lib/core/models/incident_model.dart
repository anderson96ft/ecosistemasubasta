import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Incident extends Equatable {
  final String id;
  final String productModel;
  final String reason;
  final Timestamp reportedAt;

  const Incident({
    required this.id,
    required this.productModel,
    required this.reason,
    required this.reportedAt,
  });

  factory Incident.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    return Incident(
      id: snap.id,
      productModel: data['productModel'] ?? 'N/A',
      reason: data['reason'] ?? 'Sin motivo especificado.',
      reportedAt: data['timestamp'] ?? Timestamp.now(),
    );
  }

  @override
  List<Object?> get props => [id, productModel, reason, reportedAt];
}