import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/encryption/encryption_service.dart';
import '../../../models/employee_model.dart';
import '../../../services/employee_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../core/helpers/validator_helper.dart';

/// Formulaire d'ajout/modification d'employé
class EmployeeFormScreen extends ConsumerStatefulWidget {
  final EmployeeModel? employee; // Null = ajout, non-null = modification

  const EmployeeFormScreen({super.key, this.employee});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  final _roleController = TextEditingController();
  
  DateTime? _birthdate;
  DateTime _hireDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadEmployeeData();
    }
  }

  void _loadEmployeeData() async {
    final employee = widget.employee!;
    final encryption = EncryptionService();
    
    _firstNameController.text = employee.firstName;
    _lastNameController.text = employee.lastName;
    _phoneController.text = encryption.decryptString(employee.encryptedPhone);
    _salaryController.text = encryption.decryptNumber(employee.encryptedSalary).toString();
    _roleController.text = employee.role;
    _birthdate = employee.birthdate;
    _hireDate = employee.hireDate;
    setState(() {});
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final rawdhaId = ref.watch(currentRawdhaIdProvider);
    if (rawdhaId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.error'.tr())));
      }
      return;
    }

    try {
      final encryption = EncryptionService();
      
      final employee = EmployeeModel(
        rawdhaId: rawdhaId,
        employeeId: widget.employee?.employeeId ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        encryptedPhone: encryption.encryptString(_phoneController.text.trim()),
        encryptedSalary: encryption.encryptNumber(double.parse(_salaryController.text.trim())),
        role: _roleController.text.trim(),
        birthdate: _birthdate,
        hireDate: _hireDate,
        photoUrl: widget.employee?.photoUrl,
      );

      final employeeService = EmployeeService();
      
      if (_isEditing) {
        await employeeService.updateEmployee(employee, rawdhaId);
      } else {
        await employeeService.createEmployee(employee, rawdhaId);
      }
      
      if (mounted) {
        Navigator.pop(context, employee);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'employee.edit_success'.tr() : 'employee.add_success'.tr()),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(_isEditing ? 'employee.edit_employee'.tr() : 'employee.add_employee'.tr()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Prénom
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'student.first_name'.tr(),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'finance.required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Nom
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'student.last_name'.tr(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'finance.required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Téléphone
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'employee.phone'.tr(),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'finance.required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Poste
            TextFormField(
              controller: _roleController,
              decoration: InputDecoration(
                labelText: 'employee.role'.tr(),
                prefixIcon: const Icon(Icons.work),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'finance.required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Salaire
            TextFormField(
              controller: _salaryController,
              decoration: InputDecoration(
                labelText: 'employee.salary'.tr(),
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: 'DTN',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'finance.required'.tr();
                }
                if (double.tryParse(value) == null) {
                  return 'finance.invalid'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date de naissance
            ListTile(
              leading: const Icon(Icons.cake),
              title: Text('employee.birthdate'.tr()),
              subtitle: Text(
                _birthdate != null
                    ? DateFormat('dd/MM/yyyy').format(_birthdate!)
                    : 'common.not_defined'.tr(),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _birthdate ?? DateTime(1990),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _birthdate = date);
                }
              },
            ),
            const Divider(),

            // Date d'embauche
            ListTile(
              leading: const Icon(Icons.work_history),
              title: Text('employee.hire_date'.tr()),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_hireDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _hireDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _hireDate = date);
                }
              },
            ),
            const SizedBox(height: 32),

            // Bouton de sauvegarde
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEmployee,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'common.save'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
