import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/employee_absence_model.dart';
import '../../../services/employee_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../core/helpers/date_helper.dart';

/// Dialog pour ajouter une absence
class AddAbsenceDialog extends ConsumerStatefulWidget {
  final String employeeId;
  final EmployeeService employeeService;

  const AddAbsenceDialog({
    super.key,
    required this.employeeId,
    required this.employeeService,
  });

  @override
  ConsumerState<AddAbsenceDialog> createState() => _AddAbsenceDialogState();
}

class _AddAbsenceDialogState extends ConsumerState<AddAbsenceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _type = 'sick';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _absenceTypes = [
    {'value': 'sick', 'label': 'absence.causes.sick'.tr(), 'icon': Icons.local_hospital},
    {'value': 'vacation', 'label': 'absence.causes.travel'.tr(), 'icon': Icons.beach_access},
    {'value': 'personal', 'label': 'absence.causes.medical'.tr(), 'icon': Icons.person},
    {'value': 'other', 'label': 'absence.causes.other'.tr(), 'icon': Icons.info},
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _saveAbsence() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
      
      final absence = EmployeeAbsenceModel(
        absenceId: '',
        rawdhaId: rawdhaId,
        employeeId: widget.employeeId,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonController.text.trim(),
        type: _type,
      );

      await widget.employeeService.addAbsence(rawdhaId, absence);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.success'.tr()),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.error'.tr()}: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('absence.add_absence'.tr()),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type d'absence
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'absence.type'.tr(),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _absenceTypes.map<DropdownMenuItem<String>>((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'] as String,
                    child: Row(
                      children: [
                        Icon(type['icon'] as IconData, size: 20),
                        const SizedBox(width: 8),
                        Text(type['label'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _type = value!);
                },
              ),
              const SizedBox(height: 16),

              // Raison
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'absence.cause'.tr(),
                  prefixIcon: const Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Date de début
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text('absence.start_date'.tr()),
                subtitle: Text(DateHelper.formatDateLong(context, _startDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('fr'),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),

              // Date de fin
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text('absence.end_date'.tr()),
                subtitle: Text(
                  _endDate != null
                      ? DateHelper.formatDateLong(context, _endDate!)
                      : 'absence.ongoing'.tr(),
                ),
                trailing: _endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _endDate = null),
                      )
                    : null,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? _startDate.add(const Duration(days: 1)),
                    firstDate: _startDate,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('fr'),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAbsence,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'common.save'.tr(),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
