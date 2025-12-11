/// Modèle pour un niveau scolaire (3 ans, 4 ans, 5 ans)
class SchoolLevelModel {
  final String id;
  final String name;
  final int order; // 1, 2, 3 pour le tri
  final String description;

  SchoolLevelModel({
    required this.id,
    required this.name,
    required this.order,
    this.description = '',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'order': order,
      'description': description,
    };
  }

  factory SchoolLevelModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SchoolLevelModel(
      id: id,
      name: data['name'] ?? '',
      order: data['order'] ?? 0,
      description: data['description'] ?? '',
    );
  }

  // Constantes pour les niveaux fixes
  static const String level3Id = 'level_3';
  static const String level4Id = 'level_4';
  static const String level5Id = 'level_5';
}
