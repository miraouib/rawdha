import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/parent_model.dart';
import '../../../models/payment_model.dart';
import '../../../services/parent_service.dart';
import '../../../services/payment_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class RevenueFormScreen extends ConsumerStatefulWidget {
  final String? parentId;

  const RevenueFormScreen({super.key, this.parentId});

  @override
  ConsumerState<RevenueFormScreen> createState() => _RevenueFormScreenState();
}

class _RevenueFormScreenState extends ConsumerState<RevenueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _selectedParentId;
  double _expectedAmount = 0.0;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  String _parentSearchQuery = '';
  String _paymentType = 'full'; // 'full' (Total) or 'partial' (Partiel)

  
  final PaymentService _paymentService = PaymentService();
  final ParentService _parentService = ParentService();

  @override
  void initState() {
    super.initState();
    if (widget.parentId != null) {
      _selectedParentId = widget.parentId;
      _calculateExpected();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _calculateExpected() async {
    if (_selectedParentId != null) {
      final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
      if (rawdhaId.isEmpty) return; // Prevention
      
      final amount = await _paymentService.calculateExpectedAmount(rawdhaId, _selectedParentId!);
      
      if (mounted) {
        setState(() {
          _expectedAmount = amount > 0 ? amount : 0.0; // Fallback
          // Pre-fill only if empty or default 0
          if (_amountController.text.isEmpty || _amountController.text == '0') {
             _amountController.text = _expectedAmount.toStringAsFixed(0);
          }
        });
      }
    }
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    int tempYear = _selectedYear;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => tempYear--),
                ),
                Text('$tempYear', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => tempYear++),
                ),
              ],
            ),
            content: SizedBox(
              width: 300,
              height: 300,
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
                children: List.generate(12, (index) {
                  final month = index + 1;
                  final isSelected = month == _selectedMonth && tempYear == _selectedYear;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      this.setState(() {
                         _selectedYear = tempYear;
                         _selectedMonth = month;
                         _selectedDate = DateTime(tempYear, month, 1);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('MMM', 'fr').format(DateTime(2022, month)),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor() {
    final currentAmount = double.tryParse(_amountController.text) ?? 0;
    if (currentAmount >= _expectedAmount && _expectedAmount > 0) return Colors.green;
    if (currentAmount > 0) return Colors.orange;
    return Colors.red;
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('finance.select_parent'.tr())));
      return;
    }

    final rawdhaId = ref.watch(currentRawdhaIdProvider);
    if (rawdhaId == null) return;

    setState(() => _isLoading = true);

    // 1. Check Duplicate
    final exists = await _paymentService.checkPaymentExists(rawdhaId, _selectedParentId!, _selectedMonth, _selectedYear);
    if (exists) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('finance.error_payment_exists'.tr()),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    try {
      final payment = PaymentModel(
        rawdhaId: rawdhaId,
        id: '',
        parentId: _selectedParentId!,
        amount: double.parse(_amountController.text),
        expectedAmount: _expectedAmount,
        date: _selectedDate,
        month: _selectedMonth,
        year: _selectedYear,
        note: _noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _paymentService.addPayment(rawdhaId, payment);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('finance.payment_saved'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${"common.error".tr()}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Scaffold(
      appBar: AppBar(title: Text('finance.record_revenue'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Field
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'finance.search_parent'.tr(),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (value) {
                          setState(() => _parentSearchQuery = value.toLowerCase());
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Parent Selector
                      StreamBuilder<List<ParentModel>>(
                        stream: _parentService.getParents(ref.watch(currentRawdhaIdProvider) ?? ''),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          
                          final allParents = snapshot.data!;
                          final filteredParents = allParents.where((p) {
                            // Important: Always include the selected parent in the list to avoid Dropdown error
                            if (_selectedParentId != null && p.id == _selectedParentId) return true;

                            if (_parentSearchQuery.isEmpty) return true;
                            final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
                            return fullName.contains(_parentSearchQuery) || 
                                   p.familyCode.toLowerCase().contains(_parentSearchQuery);
                          }).toList();
                          
                          filteredParents.sort((a, b) => 
                            '${a.firstName} ${a.lastName}'.compareTo('${b.firstName} ${b.lastName}')
                          );
                          
                          return DropdownButtonFormField<String>(
                            value: _selectedParentId,
                            isExpanded: true, // Fix overflow by allowing content to expand/wrap
                            decoration: InputDecoration(
                              labelText: '${"finance.parent".tr()} (${filteredParents.length} ${"finance.results".tr()})',
                              prefixIcon: const Icon(Icons.person),
                            ),
                            items: filteredParents.map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.firstName} ${p.lastName} (${p.familyCode})',
                                overflow: TextOverflow.ellipsis, // Truncate long names
                              ),
                            )).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedParentId = v;
                                _amountController.clear();
                              });
                              _calculateExpected();
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Expected Amount
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('finance.expected_amount'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${_expectedAmount.toStringAsFixed(2)} ${"finance.currency".tr()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment Type Selection (Radio Buttons)
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('finance.payment_type_full'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              value: 'full',
                              groupValue: _paymentType,
                              onChanged: (value) {
                                setState(() {
                                  _paymentType = value!;
                                  _amountController.text = _expectedAmount.toStringAsFixed(0);
                                });
                              },
                              activeColor: Colors.green,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('finance.payment_type_partial'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                              value: 'partial',
                              groupValue: _paymentType,
                              onChanged: (value) {
                                setState(() {
                                  _paymentType = value!;
                                  _amountController.clear();
                                });
                              },
                              activeColor: Colors.orange,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Amount Input
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        enabled: _paymentType == 'partial', // Disable if 'full' to prevent editing? Or allow adjustment? Usually 'full' implies fixed. Let's allow edit if needed but default is set. Valid requirement: "Total sets amount", "Partial allows entry".
                        // Logic Update based on user request "make 2 radio green and orange (delete red)". 
                        // If 'full', we enforce expectedAmount or just pre-fill?
                        // "Total" usually means the full amount. Partial means less.
                        // Let's keep it enabled but pre-filled for better UX.
                        decoration: InputDecoration(
                          labelText: '${"finance.amount_paid".tr()} (${"finance.currency".tr()})',
                          prefixIcon: const Icon(Icons.attach_money),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _paymentType == 'full' ? Colors.green : Colors.orange)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _paymentType == 'full' ? Colors.green : Colors.orange, width: 2)),
                        ),
                        // onChanged: (_) => setState(() {}), // No longer needed for color status update
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'finance.required'.tr();
                          if (double.tryParse(v) == null) return 'finance.invalid'.tr();
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      const SizedBox(height: 8),
                      // Removed dynamic status text as requested (replaced by radio selection visual).
                      
                      const SizedBox(height: 16),

                      // Date
                        InkWell(
                          onTap: () => _showMonthPicker(context),
                          child: InputDecorator(
                            decoration: InputDecoration(labelText: 'finance.month_concerned'.tr(), prefixIcon: const Icon(Icons.calendar_month)),
                            child: Text(DateFormat('MM-yyyy', 'fr').format(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Note
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(labelText: 'finance.note_optional'.tr(), prefixIcon: const Icon(Icons.note)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePayment,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('finance.add_revenue'.tr(), style: const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
