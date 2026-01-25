import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 1️⃣ Request permissions (Android 13+ / iOS)
  Future<void> requestPermissions() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );


  }

  /// ✅ Ensure FCM is ready (token exists)
  Future<void> ensureFcmReady() async {
    final token = await _fcm.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('FCM token not available yet');
    }
  }

  /// 2️⃣ Subscribe parent to school topic
  /// Topic format: school_<rawdhaId>
  Future<void> subscribeToSchool({
    required String parentId,
    required String rawdhaId,
  }) async {
    final topic = 'school_$rawdhaId';

    try {
      // 1️⃣ Make sure FCM is initialized and token exists
      await ensureFcmReady();

      // 2️⃣ Subscribe to FCM topic FIRST
      await _fcm.subscribeToTopic(topic);

      // 3️⃣ Save subscription info in Firestore (metadata only)
      await _firestore.collection('parents').doc(parentId).update({
        'subscribedTopic': topic,
        'lastFcmUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Topic subscription failed
    }
  }

  /// 3️⃣ Save notification to Firestore (history / admin trigger)
  /// ❌ Does NOT send push (Firebase Console sends push via topic)
  Future<void> sendNotification({
    required String rawdhaId,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'rawdhaId': rawdhaId,
        'title': title,
        'body': body,
        'type': type,
        'targetTopic': 'school_$rawdhaId',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error saving notification
    }
  }
}
