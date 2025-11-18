// lib/core/repositories/auth_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:subasta/core/models/user_model.dart'; // Asegúrate que la ruta sea correcta
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Emite un nuevo UserModel cada vez que el estado de autenticación de Firebase cambia.
  Stream<UserModel> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        return const UserModel(id: ''); // No autenticado
      }
      return UserModel( // Autenticado
        id: firebaseUser.uid,
        email: firebaseUser.email,
        phone: firebaseUser.phoneNumber,
      );
    });
  }

  /// Devuelve el objeto User de Firebase actual, o null si no hay.
  firebase_auth.User? getCurrentFirebaseUser() {
    return _firebaseAuth.currentUser;
  }

  // ========================================================================
  // ===    MÉTODO PARA "CONTINUAR CON GOOGLE"                         ===
  // ========================================================================

  /// Inicia el flujo de "Continuar con Google".
  Future<void> logInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el flujo
        throw Exception('Inicio de sesión con Google cancelado.');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // signInWithCredential disparará el stream 'user'
      await _firebaseAuth.signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Error Firebase en Google LogIn: ${e.code} - ${e.message}');
      throw Exception(_mapAuthErrorCode(e.code)); // Usa la función auxiliar
    } catch (e) {
      print('Error inesperado en Google LogIn: $e');
      throw Exception('Ocurrió un error al iniciar sesión con Google.');
    }
  }

  // ========================================================================
  // ===    MÉTODOS PARA PHONE AUTH (AÑADIDOS DE VUELTA)                  ===
  // ========================================================================

  /// Inicia el proceso de verificación del número de teléfono.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(firebase_auth.PhoneAuthCredential credential)
        verificationCompleted,
    required Function(firebase_auth.FirebaseAuthException e) verificationFailed,
  }) async {
    // Este método no devuelve nada, solo llama a los callbacks
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {
        // Manejado por 'codeSent', no es necesario hacer nada aquí por ahora
        print('Auto-retrieval timed out for ID: $verificationId');
      },
    );
  }

  /// Inicia sesión usando el código SMS y el ID de verificación.
  Future<void> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      // signInWithCredential disparará el stream 'user'
      await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      rethrow; // El BLoC manejará el error (ej. 'invalid-verification-code')
    }
  }

  /// Inicia sesión directamente con una credencial (usado por autocompletado de teléfono).
  Future<void> signInWithCredential(
      firebase_auth.AuthCredential credential) async {
    try {
      await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================================
  // ===           MÉTODOS DE PERFIL Y CIERRE DE SESIÓN                   ===
  // ========================================================================

  /// Crea (o actualiza) el perfil del usuario en Firestore.
  Future<void> createUserProfile({
    required String uid,
    String? phone,
    String? email,
  }) async {
    final userDoc = _firestore.collection('users').doc(uid);
    final dataToSet = {
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };
    
    final docSnapshot = await userDoc.get();
    // Escribe solo si es un usuario nuevo (doc no existe) o si hay nuevos datos
    if (dataToSet.length > 3 || !docSnapshot.exists) {
       try {
          await userDoc.set(dataToSet, SetOptions(merge: true));
          print('Perfil creado/actualizado con éxito para $uid');
       } catch (e) {
          print('Error al crear/actualizar perfil de usuario $uid: $e');
       }
    }
  }

  /// Obtiene el documento del perfil de un usuario desde la colección 'users'.
  Future<DocumentSnapshot?> getUserProfile(String userId) async {
     if (userId.isEmpty) return null;
     try {
       final doc = await _firestore.collection('users').doc(userId).get();
       return doc.exists ? doc : null;
     } catch (e) {
       print("Error getting user profile $userId: $e");
       return null;
     }
  }

  /// Cierra la sesión del usuario actual en Firebase y Google.
  Future<void> logOut() async {
    try {
       await _firebaseAuth.signOut();
       await _googleSignIn.signOut(); // Importante para Google Sign-In
       print("User logged out successfully.");
    } catch(e){
      print("Error logging out: $e");
    }
  }
  
  // Función auxiliar (privada) para mapear códigos de error a mensajes amigables
  String _mapAuthErrorCode(String code) {
    // Solo manejamos errores de Google Sign-In por ahora
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo electrónico usando otro método.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Credenciales incorrectas.';
      default:
        print('Código de error no mapeado: $code');
        return 'Ocurrió un error de autenticación.';
    }
  }
}