import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';


class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'announcements';

  // Create Announcement with Overlap Check
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    // 1. Validate Overlap
    final hasOverlap = await _checkOverlap(announcement.startDate, announcement.endDate);
    if (hasOverlap) {
      throw Exception('announcements.errors.overlap'); // Translatable key
    }

    // 2. Add to Firestore
    await _firestore.collection(_collection).add(announcement.toFirestore());
  }

  // Check if any existing announcement overlaps with the given range
  Future<bool> _checkOverlap(DateTime start, DateTime end) async {
    // We need to check if ANY announcement overlaps.
    // Overlap logic: (StartA <= EndB) and (EndA >= StartB)
    
    // Firestore cannot do this optimally in one query without complex indexes or reading all active/future.
    // Best approach: Read all announcements that end AFTER the new start date. 
    // Since announcements are cleaned up or limited, this should be small.
    // Or filter by "Active" or "Scheduled". 
    
    // Let's get all future or current announcements.
    final now = DateTime.now();
    final snapshot = await _firestore.collection(_collection)
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
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

  // Get Stream of Announcements (ordered by startDate descending)
  Stream<List<AnnouncementModel>> getAnnouncements() {
    return _firestore.collection(_collection)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Get Current Active Announcement (for Parent App)
  Future<AnnouncementModel?> getCurrentActiveAnnouncement() async {
    final now = DateTime.now();
    final snapshot = await _firestore.collection(_collection)
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .limit(1)
        .get();
        
    if (snapshot.docs.isEmpty) return null;
    
    // There should be only one if our logic works.
    return AnnouncementModel.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
