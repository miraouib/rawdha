import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/parent_model.dart';
import '../../../models/student_model.dart';
import '../../../services/student_service.dart';
import '../../../services/session_service.dart';
import '../../../core/helpers/level_helper.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../models/announcement_model.dart';
import '../../../services/announcement_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class ParentDashboardScreen extends ConsumerWidget {
  final ParentModel parent;
  const ParentDashboardScreen({super.key, required this.parent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentService = StudentService();
    final sessionService = SessionService();
    final announcementService = AnnouncementService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await sessionService.clearSession();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView( // Changed to SingleChildScrollView to avoid Expanded/ListView conflict
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branding Header: Logo & Title Centered
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Center(
                child: Consumer(
                  builder: (context, ref, child) {
                    final configAsync = ref.watch(schoolConfigByRawdhaIdProvider(parent.rawdhaId));
                    final config = configAsync.value;
                    
                    return Column(
                      children: [
                        if (config?.logoUrl != null && config!.logoUrl!.isNotEmpty)
                           Image.network(
                            config.logoUrl!,
                            height: 80,
                            errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/logo.png', height: 80),
                          )
                        else
                          Image.asset(
                            'assets/images/logo.png',
                            height: 80,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 80, color: AppTheme.primaryBlue),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          config?.name ?? 'app_name'.tr(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // En-tête Bienvenue Centré
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      '${'welcome'.tr()}, ${parent.firstName}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'parent.dashboard_subtitle'.tr(),
                      style: const TextStyle(color: AppTheme.textGray, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Section Publicité (Banner) - NOUVEAU
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('pub').doc('pub').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
                
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final link = data?['link'] as String?;
                
                if (link == null || link.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      link,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                );
              },
            ),

            // Section Mes Enfants
            StreamBuilder<List<StudentModel>>(
              stream: studentService.getStudentsByParentId(parent.rawdhaId, parent.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final students = snapshot.data ?? [];
                if (students.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: students.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _StudentCard(student: s),
                  )).toList(),
                );
              },
            ),

            // Section Annonces Actives (Directement après les enfants)
            StreamBuilder<List<AnnouncementModel>>(
              stream: announcementService.getAnnouncements(parent.rawdhaId),
              builder: (context, snapshot) {
                final allAnnouncements = snapshot.data ?? [];
                final activeAnnouncements = allAnnouncements.where((a) => a.isActiveNow()).toList();
                
                if (activeAnnouncements.isEmpty) return const SizedBox.shrink();

                // Sort by latest created
                activeAnnouncements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final mainAnnouncement = activeAnnouncements.first;

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'announcements.title'.tr(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (activeAnnouncements.length > 1)
                            TextButton(
                              onPressed: () => context.pushNamed('parent_announcements'),
                              child: Text('manager.manage_all'.tr(), style: const TextStyle(color: AppTheme.primaryBlue)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _AnnouncementHighlightCard(announcement: mainAnnouncement),
                    ],
                  ),
                );
              },
            ),
            
            // Section Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                'manager.quick_actions'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _ParentActionTile(
                    title: 'parent.unpaid_months'.tr(),
                    subtitle: 'Cliquez pour voir le détail des impayés',
                    icon: Icons.payment,
                    color: AppTheme.primaryBlue,
                    onTap: () => context.pushNamed('parent_payments_unpaid', extra: parent),
                  ),
                  const SizedBox(height: 12),
                  _ParentActionTile(
                    title: 'parent.view_school_details'.tr(),
                    subtitle: 'Coordonnées, adresse et informations',
                    icon: Icons.school,
                    color: AppTheme.primaryPurple,
                    onTap: () => context.pushNamed('parent_school_details'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ParentActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ParentActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textGray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementHighlightCard extends StatelessWidget {
  final AnnouncementModel announcement;
  const _AnnouncementHighlightCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: announcement.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: announcement.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(announcement.icon, color: announcement.color, size: 20),
              const SizedBox(width: 8),
              Text(
                announcement.tagLabel,
                style: TextStyle(color: announcement.color, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                DateHelper.formatDateShort(context, announcement.startDate),
                style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            announcement.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textGray, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentModel student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: AppTheme.accentPink.withOpacity(0.2),
      child: InkWell(
        onTap: () {
          context.pushNamed('student_modules', extra: student);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo ou Initiale
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: AppTheme.parentGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.cardShadow,
                ),
                child: student.photoUrl != null && student.photoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: Image.network(student.photoUrl!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          student.firstName[0],
                          style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student.firstName} ${student.lastName}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        LevelHelper.getLevelName(student.levelId, context),
                        style: const TextStyle(color: AppTheme.accentPink, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Icon(Icons.arrow_forward_ios, size: 18, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }
}
