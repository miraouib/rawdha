import 'package:cloud_firestore/cloud_firestore.dart';

class ParentMessageModel {
  final String id;
  final String rawdhaId;
  final String parentId;
  final String parentName;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String senderType; // 'parent' or 'admin'
  final String conversationId;

  ParentMessageModel({
    required this.id,
    required this.rawdhaId,
    required this.parentId,
    required this.parentName,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.senderType = 'parent',
    required this.conversationId,
  });

  factory ParentMessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ParentMessageModel(
      id: id,
      rawdhaId: data['rawdhaId'] ?? '',
      parentId: data['parentId'] ?? '',
      parentName: data['parentName'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      senderType: data['senderType'] ?? 'parent',
      conversationId: data['conversationId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rawdhaId': rawdhaId,
      'parentId': parentId,
      'parentName': parentName,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'senderType': senderType,
      'conversationId': conversationId,
    };
  }
}
