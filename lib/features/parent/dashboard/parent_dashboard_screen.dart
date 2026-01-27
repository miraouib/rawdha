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
import 'package:url_launcher/url_launcher.dart';
import '../../../services/notification_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

import '../../../core/widgets/parent_footer.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  final ParentModel parent;
  const ParentDashboardScreen({super.key, required this.parent});

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  late Stream<DocumentSnapshot> _pubStream;
  late Stream<List<StudentModel>> _studentsStream;
  late Stream<List<AnnouncementModel>> _announcementsStream;

  final StudentService _studentService = StudentService();
  final SessionService _sessionService = SessionService();
  final AnnouncementService _announcementService = AnnouncementService();

  @override
  void initState() {
    super.initState();
    _checkAndInitPub();
    _initNotifications();
    
    _pubStream = FirebaseFirestore.instance.collection('pub').doc('pub').snapshots();
    _studentsStream = _studentService.getStudentsByParentId(widget.parent.rawdhaId, widget.parent.id);
    _announcementsStream = _announcementService.getAnnouncements(widget.parent.rawdhaId);
  }

  Future<void> _initNotifications() async {
    final ns = NotificationService();
    await ns.requestPermissions();
    await ns.subscribeToSchool(
      parentId: widget.parent.id,
      rawdhaId: widget.parent.rawdhaId,
    );
  }

  Future<void> _checkAndInitPub() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('pub').doc('pub');
      final doc = await docRef.get();
      
      if (!doc.exists) {
        // Auto-initialize if not exists
        final now = DateTime.now();
        await docRef.set({
          'image': 'https://safekids.app/assets/images/site/slide-2.jpg',
          'link': 'https://safekids.app',
          'startDate': Timestamp.fromDate(now),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 7))),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Error initializing pub
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      bottomNavigationBar: const ParentFooter(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _sessionService.clearSession();
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
                    final configAsync = ref.watch(schoolConfigByRawdhaIdProvider(widget.parent.rawdhaId));
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
                      '${'welcome'.tr()}, ${widget.parent.firstName}',
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

            // Section Publicité (Banner)
            StreamBuilder<DocumentSnapshot>(
              stream: _pubStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null) return const SizedBox.shrink();

                final imageUrl = data['image'] as String?;
                final targetUrl = data['link'] as String?;
                final startDate = data['startDate'] as Timestamp?;
                final endDate = data['endDate'] as Timestamp?;
                
                // Hide if no image
                if (imageUrl == null || imageUrl.isEmpty) return const SizedBox.shrink();

                final now = DateTime.now();

                // Check startDate (not in future)
                if (startDate != null) {
                  if (now.isBefore(startDate.toDate())) {
                    return const SizedBox.shrink();
                  }
                } else if (data.containsKey('startDate')) {
                   // startDate exists but is empty -> hide
                   return const SizedBox.shrink();
                }

                // Check endDate (not in past)
                if (endDate != null) {
                  if (now.isAfter(endDate.toDate())) {
                    return const SizedBox.shrink();
                  }
                } else if (data.containsKey('endDate')) {
                   // endDate exists but is empty -> hide
                   return const SizedBox.shrink();
                }
                
                // If neither startDate or endDate exists at all, we might want to show it?
                // But the user said "date periode current", implying dates are required.
                // For safety, let's assume they are needed if the object exists.
                if (startDate == null && endDate == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: InkWell(
                    onTap: () async {
                      if (targetUrl != null && targetUrl.isNotEmpty) {
                        final uri = Uri.parse(targetUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Section Mes Enfants
            StreamBuilder<List<StudentModel>>(
              stream: _studentsStream,
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
              stream: _announcementsStream,
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
                    onTap: () => context.pushNamed('parent_payments_unpaid', extra: widget.parent),
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
              if (announcement.targetLevelId != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  ),
                  child: Text(
                    LevelHelper.getLevelName(announcement.targetLevelId!, context),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textGray),
                  ),
                ),
              ],
              const Spacer(),
              if (announcement.eventDate != null)
                Text(
                  DateHelper.formatDateFull(context, announcement.eventDate!),
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              else
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
