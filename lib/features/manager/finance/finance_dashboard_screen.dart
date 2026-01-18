import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/manager_footer.dart';

class FinanceDashboardScreen extends StatelessWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('finance.title'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _FinanceMenuTile(
              title: 'finance.revenue'.tr(),
              subtitle: 'finance.revenue_subtitle'.tr(),
              icon: Icons.trending_up,
              color: AppTheme.primaryBlue,
              onTap: () => context.pushNamed('finance_revenue'),
            ),
            const SizedBox(height: 20),
            _FinanceMenuTile(
              title: 'finance.expenses'.tr(),
              subtitle: 'finance.expenses_subtitle'.tr(),
              icon: Icons.trending_down,
              color: AppTheme.accentOrange,
              onTap: () => context.pushNamed('finance_expenses'),
            ),
            const SizedBox(height: 20),
            _FinanceMenuTile(
              title: 'finance.unpaid_title'.tr(),
              subtitle: 'finance.unpaid_subtitle'.tr(),
              icon: Icons.warning_amber_rounded,
              color: Colors.red,
              onTap: () => context.pushNamed('finance_unpaid'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ManagerFooter(),
    );
  }
}

class _FinanceMenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FinanceMenuTile({
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.textGray, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}
