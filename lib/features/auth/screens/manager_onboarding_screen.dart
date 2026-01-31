import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../services/manager_auth_service.dart';
import '../../../core/providers/rawdha_provider.dart';

class ManagerOnboardingScreen extends ConsumerStatefulWidget {
  const ManagerOnboardingScreen({super.key});

  @override
  ConsumerState<ManagerOnboardingScreen> createState() => _ManagerOnboardingScreenState();
}

class _ManagerOnboardingScreenState extends ConsumerState<ManagerOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      titleKey: 'onboarding.welcome_title',
      descKey: 'onboarding.welcome_desc',
      icon: Icons.celebration,
      color: Colors.blue,
    ),
    OnboardingSlide(
      titleKey: 'onboarding.students_title',
      descKey: 'onboarding.students_desc',
      icon: Icons.groups,
      color: Colors.orange,
    ),
    OnboardingSlide(
      titleKey: 'onboarding.parents_title',
      descKey: 'onboarding.parents_desc',
      icon: Icons.family_restroom,
      color: Colors.green,
    ),
    OnboardingSlide(
      titleKey: 'onboarding.modules_title',
      descKey: 'onboarding.modules_desc',
      icon: Icons.library_books,
      color: Colors.purple,
    ),
    OnboardingSlide(
      titleKey: 'onboarding.finance_title',
      descKey: 'onboarding.finance_desc',
      icon: Icons.account_balance_wallet,
      color: Colors.teal,
    ),
    OnboardingSlide(
      titleKey: 'onboarding.validation_title',
      descKey: 'onboarding.validation_desc',
      icon: Icons.verified_user,
      color: Colors.redAccent,
    ),
  ];

  Future<void> _onFinish() async {
    final managerId = ref.read(currentManagerIdProvider);
    if (managerId != null) {
      await ManagerAuthService().completeOnboarding(managerId);
    }
    if (mounted) {
      context.goNamed('manager_dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: slide.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(slide.icon, size: 100, color: slide.color),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      slide.titleKey.tr(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      slide.descKey.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppTheme.primaryBlue : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _slides.length - 1) {
                          _onFinish();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        (_currentPage == _slides.length - 1 ? 'onboarding.start' : 'onboarding.next').tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                if (_currentPage < _slides.length - 1)
                  TextButton(
                    onPressed: _onFinish,
                    child: const Text('onboarding.skip').tr(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String titleKey;
  final String descKey;
  final IconData icon;
  final Color color;

  OnboardingSlide({
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.color,
  });
}
