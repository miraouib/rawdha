import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/student_absence_service.dart';
import '../../../services/student_service.dart';
import '../../../core/widgets/manager_footer.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../models/student_absence_model.dart';
import '../../../models/student_model.dart';
import '../../../models/student_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

/// Dashboard Manager
/// 
/// Écran principal après connexion manager avec statistiques et accès rapides
class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen> {
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isGridView = prefs.getBool('dashboard_is_grid') ?? false;
      });
    }
  }

  Future<void> _toggleView() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !_isGridView;
    await prefs.setBool('dashboard_is_grid', newValue);
    if (mounted) {
      setState(() {
        _isGridView = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(currentManagerUsernameProvider) ?? 'Admin';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('app_name'.tr()),
        actions: [
          // Sélecteur de langue
          _LanguageSelector(),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleView,
            tooltip: _isGridView ? 'Vue Liste' : 'Vue Grille', // Could be localized
          ),
          const SizedBox(width: 8),

        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de bienvenue
            Text(
              '${'manager.welcome'.tr()}, $username',
              style: Theme.of(context).textTheme.displaySmall,
            ),
           
            const SizedBox(height: 24),

            // NOUVEAU: Alerte dernière absence
            _LatestAbsenceAlert(),
            
            const SizedBox(height: 32),

            // Accès rapides
            Text(
              'manager.quick_actions'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _buildQuickActions(context),
          ],
        ),
      ),
      bottomNavigationBar: const ManagerFooter(),
    );
  }



  Widget _buildQuickActions(BuildContext context) {
    // Defines actions data for simpler grid/list generation
    final actions = [
      _ActionData(
        title: 'manager.actions.manage_classes'.tr(),
        subtitle: 'manager.actions.manage_classes_desc'.tr(),
        icon: Icons.school,
        color: AppTheme.primaryPurple,
        onTap: () => context.pushNamed('school_management'),
      ),
      _ActionData(
        title: 'manager.actions.manage_students'.tr(),
        subtitle: 'manager.actions.manage_students_desc'.tr(),
        icon: Icons.school,
        color: AppTheme.primaryBlue,
        onTap: () => context.pushNamed('student_list'),
      ),
      _ActionData(
        title: 'manager.actions.manage_parents'.tr(),
        subtitle: 'manager.actions.manage_parents_desc'.tr(),
        icon: Icons.family_restroom,
        color: AppTheme.accentPink,
        onTap: () => context.pushNamed('parent_list'),
      ),
      _ActionData(
        title: 'manager.actions.manage_modules'.tr(),
        subtitle: 'manager.actions.manage_modules_desc'.tr(),
        icon: Icons.book,
        color: AppTheme.accentTeal,
        onTap: () => context.pushNamed('module_list'),
      ),
      _ActionData(
        title: 'manager.actions.manage_finance'.tr(),
        subtitle: 'manager.actions.manage_finance_desc'.tr(),
        icon: Icons.account_balance_wallet,
        color: AppTheme.accentOrange,
        onTap: () => context.pushNamed('finance_dashboard'),
      ),
      _ActionData(
        title: 'announcements.title'.tr(),
        subtitle: 'announcements.form_title'.tr(),
        icon: Icons.notifications_active,
        color: AppTheme.primaryPurple,
        onTap: () => context.pushNamed('announcement_list'),
      ),
      _ActionData(
        title: 'manager.actions.manage_hr'.tr(),
        subtitle: 'manager.actions.manage_hr_desc'.tr(),
        icon: Icons.badge,
        color: AppTheme.accentGreen,
        onTap: () => context.pushNamed('hr_management'),
      ),
      _ActionData(
        title: 'school.configuration'.tr(),
        subtitle: 'school.config_desc'.tr(),
        icon: Icons.settings,
        color: Colors.blueGrey,
        onTap: () => context.pushNamed('school_settings'),
      ),
      _ActionData(
        title: 'manager.actions.manage_absences'.tr(),
        subtitle: 'manager.actions.manage_absences_desc'.tr(),
        icon: Icons.notifications_active,
        color: Colors.orange,
        onTap: () => context.pushNamed('manager_absences'),
      ),
    ];

    if (_isGridView) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1, // Adjust as needed
        physics: const NeverScrollableScrollPhysics(),
        children: actions.map((action) => _QuickActionGridTile(action: action)).toList(),
      );
    } else {
      return Column(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuickActionTile(
              title: action.title,
              subtitle: action.subtitle,
              icon: action.icon,
              color: action.color,
              onTap: action.onTap,
            ),
          );
        }).toList(),
      );
    }
  }
}

class _ActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionData({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});
}

class _QuickActionGridTile extends StatelessWidget {
  final _ActionData action;

  const _QuickActionGridTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              action.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de statistique avec gradient


/// Tuile d'action rapide
class _QuickActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de sélection de langue
class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;
    final isArabic = currentLocale.languageCode == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageButton(
            label: '🇫🇷',
            isSelected: !isArabic,
            onTap: () => context.setLocale(const Locale('fr')),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withOpacity(0.3),
          ),
          _LanguageButton(
            label: '🇸🇦',
            isSelected: isArabic,
            onTap: () => context.setLocale(const Locale('ar')),
          ),
        ],
      ),
    );
  }
}

/// Bouton de langue individuel
class _LanguageButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.primaryBlue : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _LatestAbsenceAlert extends ConsumerStatefulWidget {
  const _LatestAbsenceAlert();

  @override
  ConsumerState<_LatestAbsenceAlert> createState() => _LatestAbsenceAlertState();
}

class _LatestAbsenceAlertState extends ConsumerState<_LatestAbsenceAlert> {
  late Stream<List<StudentAbsenceModel>> _absenceStream;
  final StudentAbsenceService _absenceService = StudentAbsenceService();
  final StudentService _studentService = StudentService();

  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    _absenceStream = _absenceService.getAllRecentAbsences(rawdhaId, limit: 1);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentAbsenceModel>>(
      stream: _absenceStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        final absence = snapshot.data!.first;
        final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';
        
        return FutureBuilder<StudentModel?>(
          future: _studentService.getStudentById(rawdhaId, absence.studentId),
          builder: (context, studentSnapshot) {
            final student = studentSnapshot.data;
            final studentName = student != null ? '${student.firstName} ${student.lastName}' : '...';

            return InkWell(
              onTap: () => context.pushNamed('manager_absences'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notification_important, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'absence.manager_alerts'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$studentName - ${'absence.causes.${absence.cause}'.tr()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateHelper.formatDateShort(context, absence.startDate),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.orange),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
