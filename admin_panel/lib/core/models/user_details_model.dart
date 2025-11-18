import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserDetails extends Equatable {
  final String uid;
  final String name;
  final String dni;
  final String email;
  final String phone;

  const UserDetails({
    required this.uid,
    required this.name,
    required this.dni,
    required this.email,
    required this.phone,
  });

  factory UserDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserDetails(
      uid: doc.id,
      name: data['name'] ?? '',
      dni: data['dni'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
    );
  }

  static UserDetails empty() {
    return const UserDetails(uid: '', name: '', dni: '', email: '', phone: '');
  }

  @override
  List<Object?> get props => [uid, name, dni, email, phone];
}