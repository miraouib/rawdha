import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/parent_model.dart';
import '../../../models/payment_model.dart';
import '../../../services/payment_service.dart';
import '../../../core/helpers/date_helper.dart';

class ParentPaymentUnpaidScreen extends StatelessWidget {
  final ParentModel parent;

  const ParentPaymentUnpaidScreen({super.key, required this.parent});

  List<DateTime> _generatePastUnpaidMonths() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    // School year starts in September
    final startYear = currentMonth >= 9 ? currentYear : currentYear - 1;
    final startDate = DateTime(startYear, 9, 1);
    
    List<DateTime> months = [];
    DateTime current = startDate;
    
    // We stop at current month (inclusive or exclusive? usually the current month is also due)
    // The user said "passed month", so we stop at now.
    while (current.isBefore(now) || (current.year == now.year && current.month == now.month)) {
      months.add(current);
      if (current.month == 12) {
        current = DateTime(current.year + 1, 1, 1);
      } else {
        current = DateTime(current.year, current.month + 1, 1);
      }
    }
    
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService();
    final allRelevantMonths = _generatePastUnpaidMonths();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('parent.unpaid_months'.tr()),
      ),
      body: FutureBuilder<double>(
        future: paymentService.calculateExpectedAmount(parent.id),
        builder: (context, expectedSnapshot) {
          final expectedMonthlyAmount = expectedSnapshot.data ?? parent.monthlyFee ?? 0.0;

          return StreamBuilder<List<PaymentModel>>(
            stream: paymentService.getPaymentsByParent(parent.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final payments = snapshot.data ?? [];
              
              // Filter only unpaid months
              final unpaidMonths = allRelevantMonths.where((m) {
                final p = _findPaymentForMonth(payments, m);
                // Status 0 or no payment doc = unpaid
                return p == null || p.status == PaymentStatus.unpaid;
              }).toList();

              if (unpaidMonths.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                        const SizedBox(height: 24),
                        Text(
                          'parent.no_unpaid_months'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, color: AppTheme.textGray),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final totalDue = unpaidMonths.length * expectedMonthlyAmount;

              return Column(
                children: [
                  // Total Due Summary
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.gradientCardShadow,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'parent.total_due'.tr(),
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateHelper.convertNumbers(context, '${totalDue.toStringAsFixed(2)} TND'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), // Added 40px bottom padding
                      itemCount: unpaidMonths.length,
                      itemBuilder: (context, index) {
                        final month = unpaidMonths[index];
                        return _UnpaidMonthTile(
                          month: month,
                          amount: expectedMonthlyAmount,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
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
}

class _UnpaidMonthTile extends StatelessWidget {
  final DateTime month;
  final double amount;

  const _UnpaidMonthTile({required this.month, required this.amount});

  @override
  Widget build(BuildContext context) {
    final monthName = DateHelper.formatMonthYear(context, month);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
        ),
        title: Text(
          monthName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'parent.unpaid_badge'.tr(),
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12),
        ),
        trailing: Text(
          DateHelper.convertNumbers(context, '${amount.toStringAsFixed(0)} TND'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
        ),
      ),
    );
  }
}
