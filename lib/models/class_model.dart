/// Modèle pour une Classe
/// 
/// Groupe d'élèves dans un niveau avec un enseignant
class ClassModel {
  final String classId;
  final String levelId; // Niveau de la classe
  final String name; // Nom de la classe
  final String? teacherId; // ID de l'enseignant (optionnel)
  final int capacity; // Capacité maximale

  ClassModel({
    required this.classId,
    required this.levelId,
    required this.name,
    this.teacherId,
    this.capacity = 25,
  });

  /// Crée une Classe depuis Firestore
  factory ClassModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ClassModel(
      classId: id,
      levelId: data['levelId'] ?? '',
      name: data['name'] ?? '',
      teacherId: data['teacherId'],
      capacity: data['capacity'] ?? 25,
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'levelId': levelId,
      'name': name,
      'teacherId': teacherId,
      'capacity': capacity,
    };
  }

  /// Copie avec modifications
  ClassModel copyWith({
    String? classId,
    String? levelId,
    String? name,
    String? teacherId,
    int? capacity,
  }) {
    return ClassModel(
      classId: classId ?? this.classId,
      levelId: levelId ?? this.levelId,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      capacity: capacity ?? this.capacity,
    );
  }
}
