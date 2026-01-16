import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/student_model.dart';
import '../../../models/student_absence_model.dart';
import '../../../services/student_absence_service.dart';
import '../../../core/helpers/date_helper.dart';

class ParentAbsenceFormScreen extends StatefulWidget {
  final StudentModel student;

  const ParentAbsenceFormScreen({super.key, required this.student});

  @override
  State<ParentAbsenceFormScreen> createState() => _ParentAbsenceFormScreenState();
}

class _ParentAbsenceFormScreenState extends State<ParentAbsenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedCause;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _causes = [
    'sick',
    'travel',
    'medical',
    'family',
    'other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final absence = StudentAbsenceModel(
        rawdhaId: widget.student.rawdhaId,
        absenceId: '',
        studentId: widget.student.studentId,
        startDate: _selectedDate,
        cause: _selectedCause!,
        description: _descriptionController.text.trim(),
      );

      await StudentAbsenceService().addAbsence(widget.student.rawdhaId, absence);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('absence.success'.tr()),
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
        title: Text('absence.report_title'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'absence.report_for'.tr()} ${widget.student.firstName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Date Selection
              Text('absence.date_label'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 7)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 20),
                      const SizedBox(width: 12),
                      Text(DateHelper.formatDateLong(context, _selectedDate)),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Cause/Reason (Dropdown)
              Text('absence.cause'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCause,
                decoration: InputDecoration(
                  hintText: 'absence.cause_hint'.tr(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _causes.map((cause) {
                  return DropdownMenuItem(
                    value: cause,
                    child: Text('absence.causes.$cause'.tr()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCause = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'absence.cause_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Description (Text Area)
              Text('absence.description'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'absence.description_hint'.tr(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('absence.submit'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
