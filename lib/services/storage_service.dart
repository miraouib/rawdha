import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads the school logo to Firebase Storage
  /// Returns the download URL
  Future<String> uploadSchoolLogo(File file, String schoolName) async {
    try {
      if (!await _checkFileSize(file)) {
        throw Exception('Image trop volumineuse. Max 2 Mo.');
      }

      // Sanitize filename and add unique ID
      final uuid = const Uuid().v4();
      final safeName = schoolName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final ref = _storage.ref().child('logos/${safeName}_$uuid.png');

      // Upload
      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {'school': schoolName},
      );

      await ref.putFile(file, metadata);

      // Get URL
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur upload Firebase: $e');
    }
  }

  Future<bool> _checkFileSize(File file) async {
    final size = await file.length();
    // 2 MB = 2 * 1024 * 1024 bytes
    return size <= (2 * 1024 * 1024);
  }
}
