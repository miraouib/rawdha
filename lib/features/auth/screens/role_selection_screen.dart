import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import 'manager_login_screen.dart';
import 'parent_login_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/session_service.dart';
import '../../../models/parent_model.dart';
import '../../../models/manager_model.dart';
import '../../../core/providers/rawdha_provider.dart';

/// Écran de sélection du rôle (Manager ou Parent)
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _sessionService = SessionService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final user = await _sessionService.tryAutoLogin();
      
      if (!mounted) return;

      if (user is ParentModel) {
        ref.read(currentRawdhaIdProvider.notifier).state = user.rawdhaId;
        context.goNamed('parent_dashboard', extra: user);
        return;
      } else if (user is ManagerModel) {
        ref.read(currentRawdhaIdProvider.notifier).state = user.rawdhaId;
        ref.read(currentManagerIdProvider.notifier).state = user.managerId;
        ref.read(currentManagerUsernameProvider.notifier).state = user.username;
        context.goNamed('manager_dashboard');
        return;
      }
    } catch (e) {
      // Auto-login failed
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Container(
                  width: 150,
                  height: 150,
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
               ),
               const SizedBox(height: 24),
               const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _LanguageSelector(),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 220,
                  height: 180,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  'app_name'.tr(),
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'welcome'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 64),
                
                _RoleCard(
                  title: 'manager.title'.tr(),
                  icon: Icons.admin_panel_settings,
                  gradient: AppTheme.primaryGradient,
                  onTap: () {
                    context.pushNamed('manager_login');
                  },
                ),
                const SizedBox(height: 16),
                
                _RoleCard(
                  title: 'parent.title'.tr(),
                  icon: Icons.family_restroom,
                  gradient: AppTheme.parentGradient,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentLoginScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.gradientCardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 24,
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
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
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
            height: 24,
            color: AppTheme.borderColor,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textGray,
          ),
        ),
      ),
    );
  }
}
