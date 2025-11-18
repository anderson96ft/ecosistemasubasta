import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageRepository {
  final FirebaseStorage _firebaseStorage;

  StorageRepository({FirebaseStorage? firebaseStorage})
      : _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  Future<String> uploadImage(Uint8List imageData) async {
    try {
      final String imageId = const Uuid().v4();
      final ref = _firebaseStorage.ref('product_images/$imageId');
      await ref.putData(imageData);
      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
}