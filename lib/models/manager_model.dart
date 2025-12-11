/// Modèle pour un Manager
/// 
/// Utilisé pour l'authentification et l'autorisation des appareils
class ManagerModel {
  final String managerId;
  final String username;
  final String passwordHash; // Hash SHA-256 du mot de passe
  final List<String> authorizedDevices; // Liste des IDs d'appareils autorisés

  ManagerModel({
    required this.managerId,
    required this.username,
    required this.passwordHash,
    required this.authorizedDevices,
  });

  /// Crée un Manager depuis Firestore
  factory ManagerModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ManagerModel(
      managerId: id,
      username: data['username'] ?? '',
      passwordHash: data['passwordHash'] ?? '',
      authorizedDevices: List<String>.from(data['authorizedDevices'] ?? []),
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'passwordHash': passwordHash,
      'authorizedDevices': authorizedDevices,
    };
  }

  /// Copie avec modifications
  ManagerModel copyWith({
    String? managerId,
    String? username,
    String? passwordHash,
    List<String>? authorizedDevices,
  }) {
    return ManagerModel(
      managerId: managerId ?? this.managerId,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      authorizedDevices: authorizedDevices ?? this.authorizedDevices,
    );
  }
}
