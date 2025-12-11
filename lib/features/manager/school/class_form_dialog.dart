import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/school_class_model.dart';
import '../../../models/employee_model.dart';
import '../../../services/school_service.dart';
import '../../../services/employee_service.dart';

/// Dialog pour ajouter/modifier une classe
class ClassFormDialog extends StatefulWidget {
  final SchoolClassModel? schoolClass; // Null = ajout
  final String levelId;

  const ClassFormDialog({
    super.key,
    this.schoolClass,
    required this.levelId,
  });

  @override
  State<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController(text: '20');
  String? _selectedTeacherId;
  
  bool _isLoading = false;
  final SchoolService _schoolService = SchoolService();
  final EmployeeService _employeeService = EmployeeService();

  @override
  void initState() {
    super.initState();
    if (widget.schoolClass != null) {
      _nameController.text = widget.schoolClass!.name;
      _capacityController.text = widget.schoolClass!.capacity.toString();
      _selectedTeacherId = widget.schoolClass!.teacherId;
    }
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newClass = SchoolClassModel(
        id: widget.schoolClass?.id ?? '', // ID vide pour Firestore.add
        name: _nameController.text.trim(),
        levelId: widget.levelId,
        teacherId: _selectedTeacherId,
        capacity: int.parse(_capacityController.text),
      );

      if (widget.schoolClass != null) {
        await _schoolService.updateClass(newClass);
      } else {
        await _schoolService.createClass(newClass);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.schoolClass != null ? 'school.class_updated'.tr() : 'school.class_added'.tr()),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.schoolClass != null ? 'school.edit_class'.tr() : 'school.add_class'.tr()),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nom
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'school.class_name_label'.tr(),
                  prefixIcon: const Icon(Icons.class_),
                ),
                validator: (value) => value!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              
              // Capacité
              TextFormField(
                controller: _capacityController,
                decoration: InputDecoration(
                  labelText: 'school.capacity_label'.tr(),
                  prefixIcon: const Icon(Icons.group),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),

              // Maîtresse (Dropdown)
              StreamBuilder<List<EmployeeModel>>(
                stream: _employeeService.getEmployees(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  
                  // Filtrer pour n'afficher que les éducatrices si besoin (TODO)
                  final employees = snapshot.data!;
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedTeacherId,
                    decoration: InputDecoration(
                      labelText: 'school.teacher_label'.tr(),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text('school.no_teacher'.tr())),
                      ...employees.map((e) => DropdownMenuItem(
                            value: e.employeeId,
                            child: Text(e.fullName),
                          )),
                    ],
                    onChanged: (value) => setState(() => _selectedTeacherId = value),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveClass,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
          child: Text(
            'common.save'.tr(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
