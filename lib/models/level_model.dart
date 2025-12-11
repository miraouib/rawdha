/// Modèle pour un Niveau scolaire
/// 
/// Exemple: Tamhidi, Ta7dhiri, etc.
class LevelModel {
  final String levelId;
  final String name; // Nom du niveau
  final String encryptedDefaultFee; // Frais par défaut (chiffré)
  final int order; // Ordre d'affichage

  LevelModel({
    required this.levelId,
    required this.name,
    required this.encryptedDefaultFee,
    required this.order,
  });

  /// Crée un Niveau depuis Firestore
  factory LevelModel.fromFirestore(Map<String, dynamic> data, String id) {
    return LevelModel(
      levelId: id,
      name: data['name'] ?? '',
      encryptedDefaultFee: data['encryptedDefaultFee'] ?? '',
      order: data['order'] ?? 0,
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'encryptedDefaultFee': encryptedDefaultFee,
      'order': order,
    };
  }

  /// Copie avec modifications
  LevelModel copyWith({
    String? levelId,
    String? name,
    String? encryptedDefaultFee,
    int? order,
  }) {
    return LevelModel(
      levelId: levelId ?? this.levelId,
      name: name ?? this.name,
      encryptedDefaultFee: encryptedDefaultFee ?? this.encryptedDefaultFee,
      order: order ?? this.order,
    );
  }
}
