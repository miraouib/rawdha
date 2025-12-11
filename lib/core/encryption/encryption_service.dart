import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service de chiffrement AES-256 pour les données sensibles
/// 
/// Ce service gère le chiffrement et déchiffrement de toutes les données sensibles:
/// - Numéros de téléphone
/// - Montants (frais, paiements)
/// - Codes parents
/// - Salaires
class EncryptionService {
  // Clé de chiffrement (32 caractères pour AES-256)
  static const String _encryptionKey = 'RawdhaAppSecureKey2024_AES256Key'; // Exactement 32 chars
  
  // IV fixe pour le MVP (permet de déchiffrer après redémarrage sans stocker l'IV en base)
  // ATTENTION: En production, il vaut mieux générer un IV unique par entrée et le stocker avec
  static const String _ivString = 'RawdhaAppInitVec'; // Exactement 16 chars
  
  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  EncryptionService() {
    // Initialiser la clé (32 bytes)
    _key = encrypt.Key.fromUtf8(_encryptionKey);
    
    // Initialiser l'IV fixe (16 bytes)
    _iv = encrypt.IV.fromUtf8(_ivString);
    
    // Créer l'encrypter avec AES en mode CBC
    _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
  }

  /// Chiffre une chaîne de caractères
  /// 
  /// Exemple:
  /// ```dart
  /// final encrypted = encryptionService.encryptString('0612345678');
  /// ```
  String encryptString(String plainText) {
    if (plainText.isEmpty) return '';
    
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Erreur de chiffrement: $e');
    }
  }

  /// Déchiffre une chaîne de caractères
  /// 
  /// Exemple:
  /// ```dart
  /// final decrypted = encryptionService.decryptString(encryptedValue);
  /// ```
  String decryptString(String encryptedText) {
    if (encryptedText.isEmpty) return '';
    
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw Exception('Erreur de déchiffrement: $e');
    }
  }

  /// Chiffre un nombre (montant, salaire, etc.)
  String encryptNumber(double number) {
    return encryptString(number.toString());
  }

  /// Déchiffre un nombre
  double decryptNumber(String encryptedNumber) {
    final decrypted = decryptString(encryptedNumber);
    return double.tryParse(decrypted) ?? 0.0;
  }

  /// Hash un mot de passe avec SHA-256
  /// Utilisé pour les mots de passe managers
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Vérifie un mot de passe contre son hash
  bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  /// Génère un code parent unique (6 chiffres)
  String generateParentCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final code = (timestamp % 1000000).toString().padLeft(6, '0');
    return code;
  }
}
