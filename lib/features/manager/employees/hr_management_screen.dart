import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/manager_footer.dart';
import '../../../core/encryption/encryption_service.dart';
import '../../../models/employee_model.dart';
import '../../../models/employee_absence_model.dart';
import '../../../services/employee_service.dart';
import 'employee_form_screen.dart';
import 'employee_detail_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/providers/rawdha_provider.dart';

/// Écran de gestion RH
/// 
/// Liste des employés avec recherche et actions
class HRManagementScreen extends ConsumerStatefulWidget {
  const HRManagementScreen({super.key});

  @override
  ConsumerState<HRManagementScreen> createState() => _HRManagementScreenState();
}

class _HRManagementScreenState extends ConsumerState<HRManagementScreen> {
  final _searchController = TextEditingController();
  final _employeeService = EmployeeService();
  
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
        title: Text('employee.employees'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddEmployee(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'common.search'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          
          // Statistiques rapides
          StreamBuilder<List<dynamic>>(
            stream: Rx.combineLatest2(
              _employeeService.getEmployees(ref.watch(currentRawdhaIdProvider) ?? ''),
              _employeeService.getAllAbsencesStream(ref.watch(currentRawdhaIdProvider) ?? ''),
              (List<EmployeeModel> employees, List<EmployeeAbsenceModel> absences) => [employees, absences],
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              }

              final employees = snapshot.data![0] as List<EmployeeModel>;
              final absences = snapshot.data![1] as List<EmployeeAbsenceModel>;

              final total = employees.length;
              final absentCount = employees.where((e) {
                // Check if this specific employee is currently absent
                return absences.any((a) => a.employeeId == e.employeeId && a.isCurrentlyAbsent);
              }).length;
              
              final present = total - absentCount;

              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'employee.stats.total'.tr(),
                        value: total.toString(),
                        icon: Icons.people,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'employee.stats.present'.tr(),
                        value: present.toString(),
                        icon: Icons.check_circle,
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'employee.stats.absent'.tr(),
                        value: absentCount.toString(),
                        icon: Icons.cancel,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Liste des employés
          Expanded(
            child: _buildEmployeeList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEmployee(),
        icon: const Icon(Icons.add),
        label: Text('employee.add_employee'.tr()),
        backgroundColor: AppTheme.primaryBlue,
      ),
      bottomNavigationBar: const ManagerFooter(),
    );
  }

  Widget _buildEmployeeList() {
    return StreamBuilder<List<EmployeeModel>>(
      stream: _employeeService.getEmployees(ref.watch(currentRawdhaIdProvider) ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: AppTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'employee.no_employee'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'employee.add_first'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          );
        }

        // Filtrer par recherche
        final employees = snapshot.data!.where((employee) {
          if (_searchController.text.isEmpty) return true;
          final query = _searchController.text.toLowerCase();
          return employee.fullName.toLowerCase().contains(query) ||
                 employee.role.toLowerCase().contains(query);
        }).toList();

        if (employees.isEmpty) {
          return Center(
            child: Text(
              'common.no_results'.tr(),
              style: TextStyle(color: AppTheme.textGray),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final employee = employees[index];
            return _EmployeeCard(
              employee: employee,
              onTap: () => _navigateToEmployeeDetail(employee),
            );
          },
        );
      },
    );
  }

  void _navigateToAddEmployee() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmployeeFormScreen(),
      ),
    );
    if (result != null) {
      // L'employé a été ajouté, le stream se mettra à jour automatiquement
    }
  }

  void _navigateToEmployeeDetail(EmployeeModel employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailScreen(employee: employee),
      ),
    );
  }
}

/// Carte de statistique compacte
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'employé
class _EmployeeCard extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback onTap;

  const _EmployeeCard({
    required this.employee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final encryption = EncryptionService();

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
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 30,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 16),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.role,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        encryption.decryptString(employee.encryptedPhone),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Flèche
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
