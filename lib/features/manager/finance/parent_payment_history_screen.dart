import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/parent_model.dart';
import '../../../models/payment_model.dart';
import '../../../services/payment_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class ParentPaymentHistoryScreen extends ConsumerWidget {
  final ParentModel parent;

  const ParentPaymentHistoryScreen({super.key, required this.parent});

  /// Generate list of months from September to current month
  List<DateTime> _generateSchoolYearMonths() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    // School year starts in September
    // If we're before September, use previous year's September
    final startYear = currentMonth >= 9 ? currentYear : currentYear - 1;
    final startDate = DateTime(startYear, 9, 1);
    
    List<DateTime> months = [];
    DateTime current = startDate;
    
    while (current.isBefore(now) || 
           (current.year == now.year && current.month == now.month)) {
      months.add(current);
      // Move to next month
      if (current.month == 12) {
        current = DateTime(current.year + 1, 1, 1);
      } else {
        current = DateTime(current.year, current.month + 1, 1);
      }
    }
    
    return months;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';
    final paymentService = PaymentService();
    final months = _generateSchoolYearMonths();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('parent.view_payments'.tr() + ' - ${parent.firstName} ${parent.lastName}'),
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: paymentService.getPaymentsByParent(rawdhaId, parent.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = snapshot.data ?? [];
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parent Info Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.accentOrange.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppTheme.accentOrange, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${parent.firstName} ${parent.lastName}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${'parent.family_code'.tr()}: ${parent.familyCode}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textGray,
                                ),
                              ),
                              if (parent.monthlyFee != null)
                                Text(
                                  '${'parent.monthly_fee'.tr()}: ${parent.monthlyFee!.toStringAsFixed(2)} ${'finance.currency'.tr()}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'parent.payment_history'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'parent.school_year'.tr(namedArgs: {'year': '${months.first.year}-${months.first.year + 1}'}),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGray,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Payment Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final payment = _findPaymentForMonth(payments, month);
                    
                    return _MonthCard(
                      month: month,
                      payment: payment,
                      expectedAmount: parent.monthlyFee ?? 0.0,
                      onTap: () {
                        // TODO: Navigate to payment detail/edit
                        _showPaymentDetails(context, month, payment, rawdhaId);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PaymentModel? _findPaymentForMonth(List<PaymentModel> payments, DateTime month) {
    try {
      return payments.firstWhere(
        (p) => p.year == month.year && p.month == month.month,
      );
    } catch (e) {
      return null;
    }
  }

  void _showPaymentDetails(BuildContext context, DateTime month, PaymentModel? payment, String rawdhaId) {
    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(month);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(monthName),
        content: payment != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${'parent.amount_paid'.tr()}: ${payment.amount.toStringAsFixed(2)} ${'finance.currency'.tr()}'),
                  Text('${'parent.payment_date'.tr()}: ${DateFormat('dd/MM/yyyy').format(payment.date)}'),
                  Text('${'parent.status'.tr()}: ${_getStatusText(payment.status)}'),
                  if (payment.note != null && payment.note!.isNotEmpty)
                    Text('${'parent.note'.tr()}: ${payment.note}'),
                ],
              )
            : Text('parent.no_payment_recorded'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('parent.close'.tr()),
          ),
          if (payment == null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pushNamed('revenue_add', extra: {
                  'parentId': parent.id,
                  'rawdhaId': rawdhaId,
                });
              },
              child: Text('parent.add_payment'.tr()),
            ),
        ],
      ),
    );
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'payment.paid'.tr();
      case PaymentStatus.partial:
        return 'payment.partial'.tr();
      case PaymentStatus.unpaid:
        return 'payment.unpaid'.tr();
    }
  }
}

class _MonthCard extends StatelessWidget {
  final DateTime month;
  final PaymentModel? payment;
  final double expectedAmount;
  final VoidCallback onTap;

  const _MonthCard({
    required this.month,
    required this.payment,
    required this.expectedAmount,
    required this.onTap,
  });

  Color _getStatusColor() {
    if (payment == null) return Colors.red;
    
    switch (payment!.status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.partial:
        return Colors.orange;
      case PaymentStatus.unpaid:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final monthName = DateFormat('MMM', 'fr_FR').format(month).toUpperCase();
    final year = month.year.toString().substring(2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              monthName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              year,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            if (payment != null) ...[
              Text(
                '${payment!.amount.toInt()} TND',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ] else ...[
              Icon(
                Icons.close,
                color: color,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
