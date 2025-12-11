import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../employees/hr_management_screen.dart';
import '../school/school_management_screen.dart';
import '../modules/module_list_screen.dart';
import '../parents/parent_list_screen.dart';
import '../students/student_list_screen.dart';
import '../finance/finance_dashboard_screen.dart';
import '../announcements/announcement_list_screen.dart';

/// Dashboard Manager
/// 
/// Écran principal après connexion manager avec statistiques et accès rapides
class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('manager.dashboard'.tr()),
        actions: [
          // Sélecteur de langue
          _LanguageSelector(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implémenter logout
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de bienvenue
            Text(
              '${'manager.welcome'.tr()}, Admin',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'manager.dashboard_subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textGray,
              ),
            ),
            const SizedBox(height: 32),
            
            // Cartes de statistiques
            _buildStatsCards(),
            
            const SizedBox(height: 24),
            
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
    );
  }

  Widget _buildStatsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'manager.stats.students'.tr(),
                value: '0',
                icon: Icons.school,
                gradient: AppTheme.primaryGradient,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'manager.stats.employees'.tr(),
                value: '0',
                icon: Icons.people,
                gradient: LinearGradient(
                  colors: [AppTheme.accentTeal, AppTheme.accentGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'manager.stats.payments'.tr(),
                value: '0',
                icon: Icons.payments,
                gradient: LinearGradient(
                  colors: [AppTheme.accentOrange, AppTheme.accentYellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'manager.stats.classes'.tr(),
                value: '0',
                icon: Icons.class_,
                gradient: AppTheme.parentGradient,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _QuickActionTile(
          title: 'manager.actions.manage_classes'.tr(),
          subtitle: 'manager.actions.manage_classes_desc'.tr(),
          icon: Icons.school,
          color: AppTheme.primaryPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SchoolManagementScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          title: 'manager.actions.manage_students'.tr(),
          subtitle: 'manager.actions.manage_students_desc'.tr(),
          icon: Icons.school,
          color: AppTheme.primaryBlue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentListScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          title: 'manager.actions.manage_parents'.tr(),
          subtitle: 'manager.actions.manage_parents_desc'.tr(),
          icon: Icons.family_restroom,
          color: AppTheme.accentPink,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentListScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          title: 'manager.actions.manage_modules'.tr(),
          subtitle: 'manager.actions.manage_modules_desc'.tr(),
          icon: Icons.book,
          color: AppTheme.accentTeal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ModuleListScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          title: 'manager.actions.manage_finance'.tr(),
          subtitle: 'manager.actions.manage_finance_desc'.tr(),
          icon: Icons.account_balance_wallet,
          color: AppTheme.accentOrange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FinanceDashboardScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          title: 'announcements.title'.tr(), 
          subtitle: 'announcements.form_title'.tr(), // Or a betterdesc
          icon: Icons.notifications_active,
          color: AppTheme.primaryPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AnnouncementListScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          title: 'manager.actions.manage_hr'.tr(),
          subtitle: 'manager.actions.manage_hr_desc'.tr(),
          icon: Icons.badge,
          color: AppTheme.accentGreen,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HRManagementScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Carte de statistique avec gradient
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.gradientCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

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
