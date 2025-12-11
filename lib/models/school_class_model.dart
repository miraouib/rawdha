/// Modèle pour une classe (ex: Groupe A, Groupe B)
class SchoolClassModel {
  final String id;
  final String name;
  final String levelId; // Lien vers SchoolLevelModel
  final String? teacherId; // Lien vers EmployeeModel (Maîtresse)
  final int capacity;

  SchoolClassModel({
    required this.id,
    required this.name,
    required this.levelId,
    this.teacherId,
    this.capacity = 20,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'levelId': levelId,
      'teacherId': teacherId,
      'capacity': capacity,
    };
  }

  factory SchoolClassModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SchoolClassModel(
      id: id,
      name: data['name'] ?? '',
      levelId: data['levelId'] ?? '',
      teacherId: data['teacherId'],
      capacity: data['capacity'] ?? 20,
    );
  }
}
