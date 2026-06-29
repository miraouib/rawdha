import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parent_message_model.dart';
import 'notification_service.dart';

class ParentMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'parent_messages';
  static const int maxMessagesPerDay = 20;
  static const int retentionDays = 7;

  String _conversationId(String rawdhaId, String parentId) => '${rawdhaId}_$parentId';

  Future<void> sendMessage({
    required String rawdhaId,
    required String parentId,
    required String parentName,
    required String message,
    String senderType = 'parent',
  }) async {
    final convId = _conversationId(rawdhaId, parentId);

    final msg = ParentMessageModel(
      id: '',
      rawdhaId: rawdhaId,
      parentId: parentId,
      parentName: parentName,
      message: message,
      createdAt: DateTime.now(),
      isRead: senderType == 'admin',
      senderType: senderType,
      conversationId: convId,
    );

    await _firestore.collection(_collection).add(msg.toFirestore());

    if (senderType == 'parent') {
      await NotificationService().sendNotification(
        rawdhaId: rawdhaId,
        title: 'Nouveau message d\'un parent',
        body: '$parentName: $message',
        type: 'parent_message',
      );
    }
  }

  Stream<List<ParentMessageModel>> getMessages(String conversationId) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: retentionDays));
    return _firestore
        .collection(_collection)
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ParentMessageModel.fromFirestore(doc.data(), doc.id))
          .where((msg) => msg.createdAt.isAfter(sevenDaysAgo))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Stream<List<ConversationSummary>> getConversations(String rawdhaId) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: retentionDays));
    return _firestore
        .collection(_collection)
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('senderType', isEqualTo: 'parent')
        .snapshots()
        .map((snapshot) {
      debugPrint('[getConversations] docs count: ${snapshot.docs.length}');
      final Map<String, List<ParentMessageModel>> grouped = {};
      for (final doc in snapshot.docs) {
        final msg = ParentMessageModel.fromFirestore(doc.data(), doc.id);
        debugPrint('[getConversations] doc createdAt=${msg.createdAt} convId="${msg.conversationId}" parentId="${msg.parentId}" isRead=${msg.isRead} senderType=${msg.senderType}');
        if (!msg.createdAt.isAfter(sevenDaysAgo)) {
          debugPrint('[getConversations] SKIP: older than 7 days');
          continue;
        }
        final key = msg.conversationId.isNotEmpty ? msg.conversationId : msg.parentId;
        debugPrint('[getConversations] group key="$key"');
        grouped.putIfAbsent(key, () => []).add(msg);
      }
      debugPrint('[getConversations] grouped keys: ${grouped.keys.toList()}');
      final summaries = grouped.entries.map((entry) {
        final msgs = entry.value;
        msgs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final unread = msgs.where((m) => !m.isRead).length;
        return ConversationSummary(
          conversationId: entry.key,
          parentId: msgs.first.parentId,
          parentName: msgs.first.parentName,
          lastMessage: msgs.first.message,
          lastMessageAt: msgs.first.createdAt,
          unreadCount: unread,
          totalMessages: msgs.length,
        );
      }).toList();
      summaries.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return summaries;
    });
  }

  Stream<int> getUnreadCount(String rawdhaId) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: retentionDays));
    return _firestore
        .collection(_collection)
        .where('rawdhaId', isEqualTo: rawdhaId)
        .where('senderType', isEqualTo: 'parent')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final createdAt = (data['createdAt'] as Timestamp).toDate();
            return createdAt.isAfter(sevenDaysAgo);
          })
          .length;
    });
  }

  Future<bool> canSendMessage(String conversationId) async {
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final snapshot = await _firestore
        .collection(_collection)
        .where('conversationId', isEqualTo: conversationId)
        .get();
    final todayCount = snapshot.docs
        .where((doc) {
          final data = doc.data();
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          return createdAt.isAfter(todayStart) || createdAt.isAtSameMomentAs(todayStart);
        })
        .length;
    return todayCount < maxMessagesPerDay;
  }

  Future<void> markAsRead(String messageId) async {
    await _firestore.collection(_collection).doc(messageId).update({
      'isRead': true,
    });
  }

  Future<void> markConversationAsRead(String conversationId) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: retentionDays));
    final snapshot = await _firestore
        .collection(_collection)
        .where('conversationId', isEqualTo: conversationId)
        .where('isRead', isEqualTo: false)
        .where('senderType', isEqualTo: 'parent')
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      if (createdAt.isAfter(sevenDaysAgo)) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  Future<void> deleteMessage(String messageId) async {
    await _firestore.collection(_collection).doc(messageId).delete();
  }

  Future<void> deleteOldMessages() async {
    final cutoff = DateTime.now().subtract(const Duration(days: retentionDays));
    final snapshot = await _firestore
        .collection(_collection)
        .where('createdAt', isLessThan: cutoff)
        .limit(500)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

class ConversationSummary {
  final String conversationId;
  final String parentId;
  final String parentName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final int totalMessages;

  ConversationSummary({
    required this.conversationId,
    required this.parentId,
    required this.parentName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.totalMessages,
  });
}
