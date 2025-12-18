import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/announcement_model.dart';
import '../../../services/announcement_service.dart';
import '../../../core/helpers/date_helper.dart';

class ParentAnnouncementScreen extends StatelessWidget {
  const ParentAnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('announcements.title'.tr()),
      ),
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: AnnouncementService().getAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allAnnouncements = snapshot.data ?? [];
          final activeAnnouncements = allAnnouncements.where((a) => a.isActiveNow()).toList();

          if (activeAnnouncements.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                    const SizedBox(height: 24),
                    Text(
                      'Aucune annonce active pour le moment.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: activeAnnouncements.length,
            itemBuilder: (context, index) {
              final announcement = activeAnnouncements[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: announcement.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(announcement.icon, size: 16, color: announcement.color),
                                const SizedBox(width: 4),
                                Text(
                                  announcement.tagLabel,
                                  style: TextStyle(
                                    color: announcement.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateHelper.formatDateShort(context, announcement.startDate),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        announcement.content,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textGray,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
