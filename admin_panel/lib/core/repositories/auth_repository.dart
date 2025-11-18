import 'dart:async';

import 'package:admin_panel/core/models/incident_model.dart';
import 'package:admin_panel/core/models/user_details_model.dart';
import 'package:admin_panel/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream que notifica los cambios en el estado de autenticación.
  /// Emite un `UserModel` que el `AuthBloc` puede usar.
  Stream<UserModel> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser == null
          ? UserModel.empty
          : UserModel(
              id: firebaseUser.uid,
              email: firebaseUser.email,
              name: firebaseUser.displayName,
            );
    });
  }

  /// Inicia sesión con email y contraseña.
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Cierra la sesión del usuario actual.
  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }
  /// Obtiene los detalles completos de un usuario desde la colección 'users'.
  ///
  /// Devuelve un `Future<UserDetails>`.
  Future<UserDetails> getUserDetails(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserDetails.fromFirestore(doc);
      }
      return UserDetails.empty();
    } catch (e) {
      print('Error al obtener detalles del usuario: $e');
      rethrow;
    }
  }

  /// Verifica si un usuario tiene algún incidente reportado en la colección 'incidents'.
  ///
  /// Devuelve `true` si encuentra al menos un incidente, `false` en caso contrario.
  Future<bool> userHasIncidents(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('incidents')
          .where('reportedUserId', isEqualTo: userId)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error al verificar incidentes del usuario: $e');
      return false; // Asumimos que no tiene incidentes si hay un error.
    }
  }

  /// Verifica si un usuario tiene el rol de 'admin'.
  Future<bool> isAdmin({required String userId}) async {
    if (userId.isEmpty) return false;
    try {
      // Lógica actualizada para ser coherente con las Cloud Functions.
      // Ahora comprueba si existe un documento con el ID del usuario en la colección 'admins'.
      final adminDoc = await _firestore.collection('admins').doc(userId).get();
      return adminDoc.exists;
    } catch (e) {
      print('Error al verificar si es admin: $e');
      return false;
    }
  }

  /// Obtiene una lista de todos los usuarios (excepto el admin actual, si se desea).
  /// NOTA: Esta operación puede ser costosa. En una app real, se paginaría.
  Future<List<UserModel>> listAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel(id: doc.id, email: doc.data()['email']))
        .toList();
  }

  /// Obtiene los incidentes reportados para un usuario.
  Future<List<Incident>> getIncidentsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('incidents')
          .where('reportedUserId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => Incident.fromSnapshot(doc)).toList();
    } catch (e) {
      print('Error al obtener incidentes: $e');
      return [];
    }
  }

  /// "Banea" a un usuario actualizando un campo en su documento.
  Future<void> banUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({'isBanned': true});
    } catch (e) {
      print('Error al banear usuario: $e');
      rethrow;
    }
  }
}