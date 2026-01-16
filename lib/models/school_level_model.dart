/// Modèle pour un niveau scolaire (3 ans, 4 ans, 5 ans)
class SchoolLevelModel {
  final String id;
  final String rawdhaId; // Lien vers la Rawdha
  final String nameAr;
  final String nameFr;
  final int order; // 1, 2, 3 pour le tri
  final String descriptionAr;
  final String descriptionFr;

  SchoolLevelModel({
    required this.id,
    required this.rawdhaId,
    required this.nameAr,
    required this.nameFr,
    required this.order,
    this.descriptionAr = '',
    this.descriptionFr = '',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'rawdhaId': rawdhaId,
      'nameAr': nameAr,
      'nameFr': nameFr,
      'order': order,
      'descriptionAr': descriptionAr,
      'descriptionFr': descriptionFr,
    };
  }

  factory SchoolLevelModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SchoolLevelModel(
      id: id,
      rawdhaId: data['rawdhaId'] ?? 'default',
      nameAr: data['nameAr'] ?? data['name'] ?? '', // Fallback for transition
      nameFr: data['nameFr'] ?? data['name'] ?? '',
      order: data['order'] ?? 0,
      descriptionAr: data['descriptionAr'] ?? data['description'] ?? '',
      descriptionFr: data['descriptionFr'] ?? data['description'] ?? '',
    );
  }

  // Constantes pour les niveaux fixes
  static const String level3Id = 'level_3';
  static const String level4Id = 'level_4';
  static const String level5Id = 'level_5';
}
