import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/encryption/encryption_service.dart';
import '../../../models/employee_model.dart';
import '../../../models/employee_absence_model.dart';
import '../../../services/employee_service.dart';
import 'employee_form_screen.dart';
import 'add_absence_dialog.dart';

/// Page de détails d'un employé
class EmployeeDetailScreen extends StatelessWidget {
  final EmployeeModel employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final encryption = EncryptionService();
    final employeeService = EmployeeService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(employee.fullName),
        actions: [
          // Modifier
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeFormScreen(employee: employee),
                ),
              );
              if (result != null) {
                // Rafraîchir
                Navigator.pop(context);
              }
            },
          ),
          // Supprimer
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context, employeeService),
          ),
        ],
      ),
      body: ListView(
        children: [
          // En-tête avec photo
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  employee.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  employee.role,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Informations personnelles
          _buildSection(
            context,
            title: 'Informations personnelles',
            children: [
              _InfoTile(
                icon: Icons.phone,
                label: 'employee.phone'.tr(),
                value: encryption.decryptString(employee.encryptedPhone),
                enableCopy: true,
              ),
              _InfoTile(
                icon: Icons.cake,
                label: 'employee.birthdate'.tr(),
                value: employee.birthdate != null
                    ? DateFormat('dd/MM/yyyy').format(employee.birthdate!)
                    : 'Non définie',
              ),
              _InfoTile(
                icon: Icons.work_history,
                label: 'Date d\'embauche',
                value: DateFormat('dd/MM/yyyy').format(employee.hireDate),
              ),
              _InfoTile(
                icon: Icons.attach_money,
                label: 'employee.salary'.tr(),
                value: '${encryption.decryptNumber(employee.encryptedSalary).toStringAsFixed(2)} DTN',
                isConfidential: true,
              ),
            ],
          ),

          // Liste des absences
          _buildSection(
            context,
            title: 'Absences',
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddAbsenceDialog(context, employeeService),
            ),
            children: [
              StreamBuilder<List<EmployeeAbsenceModel>>(
                stream: employeeService.getEmployeeAbsences(employee.employeeId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Aucune absence enregistrée',
                        style: TextStyle(color: AppTheme.textGray),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final absences = snapshot.data!;
                  final totalDays = absences.fold(0, (sum, absence) => sum + absence.durationInDays);

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        color: AppTheme.backgroundLight,
                        child: Row(
                          children: [
                            Icon(Icons.summarize, color: AppTheme.textGray, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Total des absences :',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$totalDays jour${totalDays > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ...absences.map((absence) {
                        return _AbsenceTile(absence: absence);
                      }).toList(),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, EmployeeService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'employé'),
        content: Text('Voulez-vous vraiment supprimer ${employee.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              await service.deleteEmployee(employee.employeeId);
              if (context.mounted) {
                Navigator.pop(context); // Dialog
                Navigator.pop(context); // Detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Employé supprimé')),
                );
              }
            },
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAbsenceDialog(BuildContext context, EmployeeService service) {
    showDialog(
      context: context,
      builder: (context) => AddAbsenceDialog(
        employeeId: employee.employeeId,
        employeeService: service,
      ),
    );
  }
}



/// Tuile d'information
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isConfidential;
  final bool enableCopy;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isConfidential = false,
    this.enableCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(label),
      subtitle: Text(
        value,
        style: TextStyle(
          fontWeight: isConfidential ? FontWeight.bold : FontWeight.normal,
          color: isConfidential ? AppTheme.accentGreen : null,
        ),
      ),
      trailing: enableCopy
          ? IconButton(
              icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
              onPressed: () => _copyToClipboard(context),
            )
          : null,
      onTap: enableCopy ? () => _copyToClipboard(context) : null,
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copié'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// Tuile d'absence
class _AbsenceTile extends StatelessWidget {
  final EmployeeAbsenceModel absence;

  const _AbsenceTile({required this.absence});

  @override
  Widget build(BuildContext context) {
    // ... (précédent code setup variables)
    final isOngoing = absence.endDate == null;
    final isCurrent = absence.isCurrentlyAbsent;

    Color typeColor;
    IconData typeIcon;
    switch (absence.type) {
      case 'sick':
        typeColor = AppTheme.errorRed;
        typeIcon = Icons.local_hospital;
        break;
      case 'vacation':
        typeColor = AppTheme.accentTeal;
        typeIcon = Icons.beach_access;
        break;
      case 'personal':
        typeColor = AppTheme.accentOrange;
        typeIcon = Icons.person;
        break;
      default:
        typeColor = AppTheme.textGray;
        typeIcon = Icons.info;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: typeColor.withOpacity(0.1),
        child: Icon(typeIcon, color: typeColor, size: 20),
      ),
      title: Text(absence.reason.isEmpty ? 'Absence' : absence.reason),
      subtitle: Text(
        '${DateFormat('dd/MM/yyyy').format(absence.startDate)} - '
        '${isOngoing ? 'En cours' : DateFormat('dd/MM/yyyy').format(absence.endDate!)} '
        '(${absence.durationInDays} jour${absence.durationInDays > 1 ? 's' : ''})',
      ),
      trailing: isCurrent
          ? Chip(
              label: const Text('En cours', style: TextStyle(fontSize: 11)),
              backgroundColor: AppTheme.errorRed.withOpacity(0.1),
              labelStyle: TextStyle(color: AppTheme.errorRed),
            )
          : null,
      onLongPress: () => _showDeleteAbsenceDialog(context, absence),
    );
  }

  void _showDeleteAbsenceDialog(BuildContext context, EmployeeAbsenceModel absence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'absence'),
        content: const Text('Voulez-vous vraiment supprimer cette absence ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final employeeService = EmployeeService();
              await employeeService.deleteAbsence(absence.absenceId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Absence supprimée')),
                );
              }
            },
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
