import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/student_model.dart';
import '../../../models/parent_model.dart';
import '../../../models/school_level_model.dart';
import '../../../services/student_service.dart';
import '../../../services/parent_service.dart';
import '../../../services/school_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class StudentFormScreen extends ConsumerStatefulWidget {
  final StudentModel? student;

  const StudentFormScreen({super.key, this.student});

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  // final _monthlyFeeController = TextEditingController(); // Removed per request
  String _gender = 'boy';
  String? _selectedLevelId;
  String? _selectedParentId;
  DateTime? _birthdate;
  
  bool _isLoading = false;
  String _parentSearchQuery = '';

  late Stream<List<SchoolLevelModel>> _levelsStream;
  late Future<List<ParentModel>> _parentsFuture;
  
  final StudentService _studentService = StudentService();
  final ParentService _parentService = ParentService();
  final SchoolService _schoolService = SchoolService();

  @override
  void initState() {
    super.initState();
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    _levelsStream = _schoolService.getLevels(rawdhaId);
    _parentsFuture = _parentService.getParents(rawdhaId);

    if (widget.student != null) {
      _firstNameController.text = widget.student!.firstName;
      _lastNameController.text = widget.student!.lastName;
      // _monthlyFeeController.text = widget.student!.monthlyFee.toString(); 
      _gender = widget.student!.gender;
      _selectedLevelId = widget.student!.levelId.isNotEmpty ? widget.student!.levelId : null;
      _selectedParentId = widget.student!.parentIds.isNotEmpty ? widget.student!.parentIds.first : null;
      _birthdate = widget.student!.birthdate;
    } else {
      // _monthlyFeeController.text = '0.0'; 
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    // _monthlyFeeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(2020),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthdate) {
      setState(() {
        _birthdate = picked;
      });
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('student.validation.select_parent'.tr())));
      return;
    }
    if (_selectedLevelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('student.validation.select_level'.tr())));
      return;
    }

    final rawdhaId = ref.watch(currentRawdhaIdProvider);
    if (rawdhaId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('student.validation.rawdha_not_found'.tr())));
      }
      return;
    }

    try {
      final student = StudentModel(
        rawdhaId: rawdhaId,
        studentId: widget.student?.studentId ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _gender,
        parentIds: [_selectedParentId!], // Linking logic
        levelId: _selectedLevelId!,
        encryptedMonthlyFee: '', // Fee later
        monthlyFee: 0.0, // Removed from form, defaults to 0
        birthdate: _birthdate,
        photoUrl: widget.student?.photoUrl,
        createdAt: widget.student?.createdAt ?? DateTime.now(),
        active: true,
      );


      if (widget.student == null) {
        await _studentService.addStudent(rawdhaId, student);
      } else {
        await _studentService.updateStudent(rawdhaId, student);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('student.validation.saved'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'common.error'.tr()}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.student == null ? 'student.new_student'.tr() : 'student.edit_student'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Identity
              _buildIdentitySection(),
              const SizedBox(height: 24),
              
              // 2. School Info (Level)
              _buildLevelSelector(),
              const SizedBox(height: 24),

              // 3. Parent Link
              _buildParentSelector(),
              SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveStudent,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator()
                    : Text('common.save'.tr(), style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('student.identity'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'student.first_name'.tr(), prefixIcon: const Icon(Icons.person)),
              validator: (v) => v!.isEmpty ? 'common.required'.tr() : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'student.last_name'.tr(), prefixIcon: const Icon(Icons.person_outline)),
              validator: (v) => v!.isEmpty ? 'common.required'.tr() : null,
            ),
            const SizedBox(height: 12),
            // Monthly fee field removed
            /*
            TextFormField(
              controller: _monthlyFeeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Frais mensuels (DZD)', prefixIcon: Icon(Icons.attach_money)),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                if (double.tryParse(v) == null) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            */
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: InputDecoration(labelText: 'student.gender'.tr(), prefixIcon: const Icon(Icons.wc)),
                    items: [
                      DropdownMenuItem(value: 'boy', child: Text('student.boy'.tr())),
                      DropdownMenuItem(value: 'girl', child: Text('student.girl'.tr())),
                    ],
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: 'student.birthdate'.tr(), prefixIcon: const Icon(Icons.calendar_today)),
                      child: Text(
                        _birthdate != null 
                          ? DateFormat('dd/MM/yyyy').format(_birthdate!) 
                          : 'student.choose'.tr(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    return StreamBuilder<List<SchoolLevelModel>>(
      stream: _levelsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final levels = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('student.schooling'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedLevelId,
                  decoration: InputDecoration(labelText: 'student.level'.tr(), prefixIcon: const Icon(Icons.school)),
                  items: levels.map((l) => DropdownMenuItem(
                    value: l.id, 
                    child: Text(context.locale.languageCode == 'ar' ? l.nameAr : l.nameFr),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedLevelId = v),
                  validator: (v) => v == null ? 'common.required'.tr() : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParentSelector() {
    return FutureBuilder<List<ParentModel>>(
      future: _parentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        
        final allParents = snapshot.data ?? [];
        
        // Filter based on search query
        final filteredParents = allParents.where((p) {
          // Always keep the selected parent in the list
          if (_selectedParentId != null && p.id == _selectedParentId) return true;

          if (_parentSearchQuery.isEmpty) return true;
          final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
          return fullName.contains(_parentSearchQuery) || 
                 p.familyCode.toLowerCase().contains(_parentSearchQuery);
        }).toList();

        filteredParents.sort((a, b) => 
          '${a.firstName} ${a.lastName}'.compareTo('${b.firstName} ${b.lastName}')
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('student.parent_resp'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
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

                DropdownButtonFormField<String>(
                  value: _selectedParentId,
                  decoration: InputDecoration(
                    labelText: '${"student.select_parent_hint".tr()} (${filteredParents.length} ${"finance.results".tr()})', 
                    prefixIcon: const Icon(Icons.family_restroom)
                  ),
                  items: filteredParents.map((p) => DropdownMenuItem(
                    value: p.id, 
                    child: Text(
                      '${p.firstName} ${p.lastName} (${p.phone})', 
                      overflow: TextOverflow.ellipsis
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedParentId = v),
                  validator: (v) => v == null ? 'common.required'.tr() : null,
                  isExpanded: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
