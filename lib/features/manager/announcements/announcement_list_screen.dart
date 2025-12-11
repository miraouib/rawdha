import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/announcement_model.dart';
import '../../../services/announcement_service.dart';
import 'announcement_form_screen.dart';

class AnnouncementListScreen extends StatelessWidget {
  const AnnouncementListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('announcements.title'.tr()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnnouncementFormScreen()),
          );
        },
        label: Text('announcements.new_announcement'.tr()),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: AnnouncementService().getAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${"common.error".tr()}: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'announcements.title'.tr(), // Just a placeholder if empty
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final announcements = snapshot.data!;
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              final isActive = announcement.isActiveNow();
              final isPast = DateTime.now().isAfter(announcement.endDate);
              final statusLabel = isActive 
                  ? 'announcements.status.active'.tr()
                  : isPast 
                      ? 'announcements.status.past'.tr()
                      : 'announcements.status.scheduled'.tr();
              
              Color statusColor = isActive ? Colors.green : (isPast ? Colors.grey : Colors.orange);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: announcement.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(announcement.icon, size: 16, color: announcement.color),
                                const SizedBox(width: 4),
                                Text(
                                  announcement.tagLabel,
                                  style: TextStyle(color: announcement.color, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        announcement.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        announcement.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textGray),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.date_range, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat('dd/MM', 'fr').format(announcement.startDate)} - ${DateFormat('dd/MM/yyyy', 'fr').format(announcement.endDate)}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAnnouncement(context, announcement.id),
                          ),
                        ],
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

  Future<void> _deleteAnnouncement(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('common.delete'.tr()),
        content: Text('announcements.confirm_delete'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('common.cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AnnouncementService().deleteAnnouncement(id);
    }
  }
}
