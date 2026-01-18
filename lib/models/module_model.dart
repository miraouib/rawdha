import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour un module pédagogique (thème de la semaine)
class ModuleModel {
  final String rawdhaId;
  final String id;
  final String titleAr;
  final String titleFr;
  final String descriptionAr;
  final String descriptionFr;
  final String levelId; // Niveau associé (3, 4, 5 ans)
  final DateTime startDate;
  final DateTime endDate;
  
  // Contenu éducatif - These could also be localized if needed, but for now we'll stick to title/desc
  // Many modules use the same letter/number but different words
  final String letter;
  final String word;
  final String number;
  final String color;
  final String? prayer;
  final String? song;

  ModuleModel({
    required this.rawdhaId,
    required this.id,
    required this.titleAr,
    required this.titleFr,
    required this.descriptionAr,
    required this.descriptionFr,
    required this.levelId,
    required this.startDate,
    required this.endDate,
    this.letter = '',
    this.word = '',
    this.number = '',
    this.color = '',
    this.prayer,
    this.song,
  });

  /// Get title based on locale
  String getTitle(String languageCode) => languageCode == 'ar' ? titleAr : titleFr;
  
  /// Get description based on locale
  String getDescription(String languageCode) => languageCode == 'ar' ? descriptionAr : descriptionFr;

  /// Vérifie si le module est actif aujourd'hui
  bool get isCurrentlyActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    return (today.isAfter(start) || today.isAtSameMomentAs(start)) && 
           (today.isBefore(end) || today.isAtSameMomentAs(end));
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rawdhaId': rawdhaId,
      'titleAr': titleAr,
      'titleFr': titleFr,
      'descriptionAr': descriptionAr,
      'descriptionFr': descriptionFr,
      'levelId': levelId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'content': {
        'letter': letter,
        'word': word,
        'number': number,
        'color': color,
        'prayer': prayer,
        'song': song,
      }
    };
  }

  factory ModuleModel.fromFirestore(Map<String, dynamic> data, String id) {
    final content = data['content'] as Map<String, dynamic>? ?? {};
    
    return ModuleModel(
      id: id,
      rawdhaId: data['rawdhaId'] ?? '',
      titleAr: data['titleAr'] ?? data['title'] ?? '',
      titleFr: data['titleFr'] ?? data['title'] ?? '',
      descriptionAr: data['descriptionAr'] ?? data['description'] ?? '',
      descriptionFr: data['descriptionFr'] ?? data['description'] ?? '',
      levelId: data['levelId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      letter: content['letter'] ?? '',
      word: content['word'] ?? '',
      number: content['number'] ?? '',
      color: content['color'] ?? '',
      prayer: content['prayer'],
      song: content['song'],
    );
  }
}
