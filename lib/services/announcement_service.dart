import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';


class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'announcements';

  // Create Announcement with Overlap Check
  Future<void> createAnnouncement(String rawdhaId, AnnouncementModel announcement) async {
    // 1. Validate Overlap
    final hasOverlap = await _checkOverlap(announcement.rawdhaId, announcement.startDate, announcement.endDate);
    if (hasOverlap) {
      throw Exception('announcements.errors.overlap'); // Translatable key
    }

    // 2. Add to Firestore
    await _firestore.collection(_collection).add(announcement.toFirestore());
  }

  // Check if any existing announcement overlaps with the given range for a rawdha
  Future<bool> _checkOverlap(String rawdhaId, DateTime start, DateTime end) async {
    // ...
    final now = DateTime.now();
    final snapshot = await _firestore.collection(_collection)
        .where('rawdhaId', isEqualTo: rawdhaId)
        .get();

    for (var doc in snapshot.docs) {
      final existingStart = (doc['startDate'] as Timestamp).toDate();
      final existingEnd = (doc['endDate'] as Timestamp).toDate();
      
      // Check overlap
      if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
        return true;
      }
    }
    return false;
  }

  // Get Stream of Announcements (ordered by startDate descending) pour une rawdha
  Stream<List<AnnouncementModel>> getAnnouncements(String rawdhaId) {
    return _firestore.collection(_collection)
        .where('rawdhaId', isEqualTo: rawdhaId)
        .snapshots()
        .map((snapshot) {
      final announcements = snapshot.docs.map((doc) {
        return AnnouncementModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Sort in-memory to avoid Firestore composite index requirement
      announcements.sort((a, b) => b.startDate.compareTo(a.startDate)); // Descending
      return announcements;
    });
  }

  // Get Current Active Announcement (for Parent App) pour une rawdha
  Future<AnnouncementModel?> getCurrentActiveAnnouncement(String rawdhaId) async {
    final now = DateTime.now();
    final snapshot = await _firestore.collection(_collection)
        .where('rawdhaId', isEqualTo: rawdhaId)
        .get();
        
    final activeAnnouncements = snapshot.docs
        .map((doc) => AnnouncementModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .where((a) => a.isActiveNow())
        .toList();

    if (activeAnnouncements.isEmpty) return null;
    
    // Sort to get the most relevant one if multiple (overlap check should prevent this anyway)
    activeAnnouncements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return activeAnnouncements.first;
  }

  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
