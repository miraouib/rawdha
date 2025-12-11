import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum AnnouncementTag {
  info,
  warning,
  event,
}

class AnnouncementModel {
  final String id;
  final String title;
  final AnnouncementTag tag;
  final String content;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final String createdBy; // Manager ID

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.tag,
    required this.content,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.createdBy,
  });

  bool isActiveNow() {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  factory AnnouncementModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AnnouncementModel(
      id: id,
      title: data['title'] ?? '',
      tag: _parseTag(data['tag']),
      content: data['content'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'tag': tag.name,
      'content': content,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  static AnnouncementTag _parseTag(String? value) {
    if (value == null) return AnnouncementTag.info;
    try {
      return AnnouncementTag.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return AnnouncementTag.info;
    }
  }

  // UI Helpers
  Color get color {
    switch (tag) {
      case AnnouncementTag.info: return Colors.blue;
      case AnnouncementTag.warning: return Colors.orange;
      case AnnouncementTag.event: return Colors.purple;
    }
  }

  IconData get icon {
    switch (tag) {
      case AnnouncementTag.info: return Icons.info;
      case AnnouncementTag.warning: return Icons.warning;
      case AnnouncementTag.event: return Icons.event;
    }
  }

  String get tagLabel {
    switch (tag) {
      case AnnouncementTag.info: return 'announcements.tags.info'.tr();
      case AnnouncementTag.warning: return 'announcements.tags.warning'.tr();
      case AnnouncementTag.event: return 'announcements.tags.event'.tr();
    }
  }
}
