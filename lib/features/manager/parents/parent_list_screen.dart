import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/level_helper.dart';
import '../../../models/parent_model.dart';
import '../../../models/student_model.dart';
import '../../../services/parent_service.dart';
import '../../../services/student_service.dart';
import '../../../models/payment_model.dart';
import '../../../services/payment_service.dart';
import '../../../services/school_service.dart'; // Import
import '../../../models/school_config_model.dart'; // Import
import '../../../core/helpers/date_helper.dart';
import 'parent_form_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../core/widgets/manager_footer.dart';

class ParentListScreen extends ConsumerStatefulWidget {
  const ParentListScreen({super.key});

  @override
  ConsumerState<ParentListScreen> createState() => _ParentListScreenState();
}

class _ParentListScreenState extends ConsumerState<ParentListScreen> {
  final ParentService _parentService = ParentService();
  final SchoolService _schoolService = SchoolService();
  
  late Stream<SchoolConfigModel> _configStream;
  late Future<List<ParentModel>> _parentsFuture;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    _configStream = _schoolService.getSchoolConfig(rawdhaId);
    _loadParents();
  }

  void _loadParents({bool forceRefresh = false}) {
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    setState(() {
      _parentsFuture = _parentService.getParents(rawdhaId, forceRefresh: forceRefresh);
    });
  }

  Future<void> _onRefresh() async {
    _loadParents(forceRefresh: true);
    await _parentsFuture;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('parent.management'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'common.refresh'.tr(),
            onPressed: () => _loadParents(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'parent.search_parent'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<SchoolConfigModel>(
              stream: _configStream,
              builder: (context, configSnapshot) {
                final schoolCode = configSnapshot.data?.schoolCode ?? '';
                
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: FutureBuilder<List<ParentModel>>(
                    future: _parentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text('common.error'.tr()),
                              Text(snapshot.error.toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _onRefresh, child: Text('common.retry'.tr())),
                            ],
                          ),
                        );
                      }
  
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: _buildEmptyState(context),
                          ),
                        );
                      }
  
                      // Filter list
                      final parents = snapshot.data!.where((parent) {
                        final query = _searchQuery;
                        return parent.firstName.toLowerCase().contains(query) ||
                            parent.lastName.toLowerCase().contains(query) ||
                            parent.phone.contains(query) ||
                            parent.familyCode.toLowerCase().contains(query) ||
                            parent.spouseName.toLowerCase().contains(query) ||
                            parent.spousePhone.contains(query);
                      }).toList()
                      ..sort((a, b) {
                         int cmp = a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
                         if (cmp != 0) return cmp;
                         return a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
                      });
  
                      if (parents.isEmpty) {
                        return Center(child: Text('common.search'.tr() + ': "$_searchQuery"'));
                      }
  
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: parents.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final parent = parents[index];
                          return _ParentCard(
                            parent: parent, 
                            schoolCode: schoolCode,
                            onDelete: () => _deleteParent(parent),
                          );
                        },
                      );
                    },
                  ),
                );
              }
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushNamed('parent_add');
        },
        label: Text('parent.add_parent'.tr()),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryBlue,
      ),
      bottomNavigationBar: const ManagerFooter(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom, size: 80, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'parent.no_parent'.tr(),
            style: const TextStyle(fontSize: 18, color: AppTheme.textGray),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteParent(ParentModel parent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('common.delete'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('parent.delete_warning_title'.tr()),
            const SizedBox(height: 8),
            Text(
              'parent.delete_warning_student'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text('parent.delete_warning_restore'.tr()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('parent.delete_confirm_btn'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final rawdhaId = ref.read(currentRawdhaIdProvider);
        if (rawdhaId == null) return;

        await _parentService.deleteParentWithStudents(rawdhaId, parent.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('common.success'.tr()), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _ParentCard extends StatelessWidget {
  final ParentModel parent;
  final String schoolCode;
  final VoidCallback onDelete;

  const _ParentCard({
    required this.parent, 
    required this.schoolCode,
    required this.onDelete,
  });

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copié: $text')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentOrange.withOpacity(0.1),
          child: const Icon(Icons.person, color: AppTheme.accentOrange),
        ),
        title: Text(
          '${parent.firstName} ${parent.lastName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _copyToClipboard(context, parent.phone),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 14, color: AppTheme.textGray),
                  const SizedBox(width: 4),
                  Text(parent.phone, style: const TextStyle(decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy, size: 12, color: AppTheme.primaryBlue),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (schoolCode.isNotEmpty)
                  _CodeBadge(label: 'parent.school_label'.tr(), code: schoolCode, color: Colors.purple),
                _CodeBadge(label: 'parent.family_id_short'.tr(), code: parent.familyCode, color: Colors.blue),
              ],
            ),
          ],
        ),
        children: [
          if (parent.spouseName.isNotEmpty) ...[
             const Divider(),
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('parent.spouse_name'.tr(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(parent.spouseName, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (parent.spousePhone.isNotEmpty)
                      Flexible(
                        child: InkWell(
                          onTap: () => _copyToClipboard(context, parent.spousePhone),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.phone, size: 16, color: AppTheme.textGray),
                              const SizedBox(width: 4),
                              Flexible(child: Text(parent.spousePhone, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy, size: 12, color: AppTheme.primaryBlue),
                         ],
                       ),
                     ),
                   ),
                  ],
                ),
             ),
          ],
          const Divider(),
          _ParentChildrenList(parentId: parent.id),
          _ParentPaymentHistory(parentId: parent.id),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.account_balance_wallet, size: 18),
                  label: Text('parent.view_payments'.tr()),
                  onPressed: () {
                    context.pushNamed('parent_payment_history', extra: parent);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text('common.edit'.tr()),
                  onPressed: () {
                    context.pushNamed('parent_edit', extra: parent);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: Text('common.delete'.tr(), style: const TextStyle(color: Colors.red)),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  final String label;
  final String code;
  final Color color;

  const _CodeBadge({required this.label, required this.code, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.code_copied'.tr())));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          '$label: $code',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ParentChildrenList extends ConsumerStatefulWidget {
  final String parentId;

  const _ParentChildrenList({required this.parentId});

  @override
  ConsumerState<_ParentChildrenList> createState() => _ParentChildrenListState();
}

class _ParentChildrenListState extends ConsumerState<_ParentChildrenList> {
  late Stream<List<StudentModel>> _childrenStream;
  final StudentService _studentService = StudentService();

  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    _childrenStream = _studentService.getStudentsByParentId(rawdhaId, widget.parentId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentModel>>(
      stream: _childrenStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); 
        }

        final students = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('parent.children_enrolled'.tr() + ' :', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ),
            ...students.map((student) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 12,
                backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
                child: student.photoUrl == null ? Text(student.firstName[0], style: const TextStyle(fontSize: 10)) : null,
              ),
              title: Text('${student.firstName} ${student.lastName}'),
              subtitle: Text(student.levelId.isNotEmpty ? LevelHelper.getLevelName(student.levelId, context) : 'common.unknown'.tr()),
              trailing: const Icon(Icons.chevron_right, size: 16),
              onTap: () {
                // Future: Navigate to student detail
              },
            )),
          ],
        );
      },
    );
  }
}

class _ParentPaymentHistory extends ConsumerStatefulWidget {
  final String parentId;

  const _ParentPaymentHistory({required this.parentId});

  @override
  ConsumerState<_ParentPaymentHistory> createState() => _ParentPaymentHistoryState();
}

class _ParentPaymentHistoryState extends ConsumerState<_ParentPaymentHistory> {
  late Stream<List<PaymentModel>> _paymentsStream;
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    _paymentsStream = _paymentService.getPaymentsByParent(rawdhaId, widget.parentId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentModel>>(
      stream: _paymentsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final payments = snapshot.data!;
        if (payments.isEmpty) return const SizedBox.shrink();

        final config = ref.watch(schoolConfigProvider).value;
        final startMonth = config?.paymentStartMonth ?? 9;
        
        // Calculate Start Date logic (same as other screens)
        final now = DateTime.now();
        final startYear = now.month >= startMonth ? now.year : now.year - 1;
        final startDate = DateTime(startYear, startMonth, 1);

        // Filter payments to hide those before start date
        final filteredPayments = payments.where((p) {
           final pDate = DateTime(p.year, p.month, 1);
           return !pDate.isBefore(startDate);
        }).toList();

        if (filteredPayments.isEmpty) return const SizedBox.shrink();

        // Sort by Date Descending
        filteredPayments.sort((a, b) => b.date.compareTo(a.date));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('parent.payment_history_short'.tr() + ' :', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ),
            SizedBox(
              height: 60,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: filteredPayments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final p = filteredPayments[index];
                  Color color = Colors.grey;
                  if (p.status == PaymentStatus.paid) color = Colors.green;
                  else if (p.status == PaymentStatus.partial) color = Colors.orange;
                  else if (p.status == PaymentStatus.unpaid) color = Colors.red;

                  return Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateHelper.formatDateShort(context, p.date).split(' ').last.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        Text('${p.amount.toInt()}', style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
