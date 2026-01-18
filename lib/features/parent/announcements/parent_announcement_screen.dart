import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/announcement_model.dart';
import '../../../services/announcement_service.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../core/helpers/level_helper.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class ParentAnnouncementScreen extends ConsumerWidget {
  const ParentAnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('announcements.title'.tr()),
      ),
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: AnnouncementService().getAnnouncements(rawdhaId),
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
                          if (announcement.targetLevelId != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              ),
                              child: Text(
                                LevelHelper.getLevelName(announcement.targetLevelId!, context),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textGray),
                              ),
                            ),
                          ],
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
