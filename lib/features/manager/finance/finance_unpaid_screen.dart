import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/payment_model.dart';
import '../../../models/parent_model.dart';
import '../../../services/payment_service.dart';
import '../../../services/parent_service.dart';

class FinanceUnpaidScreen extends StatefulWidget {
  const FinanceUnpaidScreen({super.key});

  @override
  State<FinanceUnpaidScreen> createState() => _FinanceUnpaidScreenState();
}

class _FinanceUnpaidScreenState extends State<FinanceUnpaidScreen> {
  DateTime _currentMonth = DateTime.now();
  final PaymentService _paymentService = PaymentService();
  final ParentService _parentService = ParentService();
  String _revenueSearchQuery = '';

  void _changeMonth(int increment) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + increment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Non Payés'),
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
                Text(
                  DateFormat('MMMM yyyy', 'fr_FR').format(_currentMonth).toUpperCase(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un parent',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) => setState(() => _revenueSearchQuery = value.toLowerCase()),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<ParentModel>>(
              stream: _parentService.getParents(),
              builder: (context, parentSnapshot) {
                if (!parentSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final allParents = parentSnapshot.data!;

                return StreamBuilder<List<PaymentModel>>(
                  stream: _paymentService.getPaymentsByMonth(_currentMonth.month, _currentMonth.year),
                  builder: (context, paymentSnapshot) {
                    if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final payments = paymentSnapshot.data ?? [];
                    final paidParentIds = payments.map((p) => p.parentId).toSet();

                    final unpaidParents = allParents.where((p) {
                      if (paidParentIds.contains(p.id)) return false;
                      if (_revenueSearchQuery.isNotEmpty) {
                        final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
                        if (!fullName.contains(_revenueSearchQuery)) return false;
                      }
                      return true;
                    }).toList();

                    if (unpaidParents.isEmpty) {
                      return const Center(child: Text('Tout le monde a payé ! 🎉', style: TextStyle(fontSize: 18, color: Colors.grey)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: unpaidParents.length,
                      itemBuilder: (context, index) {
                        final parent = unpaidParents[index];
                        final monthlyFee = parent.monthlyFee ?? 0.0;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              child: const Icon(Icons.warning, color: Colors.red),
                            ),
                            title: Text('${parent.firstName} ${parent.lastName}'),
                            subtitle: Text('Montant attendu: ${monthlyFee > 0 ? monthlyFee : "??"} TND'),
                            trailing: ElevatedButton(
                              child: const Text('Payer'),
                              onPressed: () {
                                context.pushNamed('revenue_add', extra: parent.id);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
