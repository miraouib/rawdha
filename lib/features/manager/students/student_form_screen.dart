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
  
  final StudentService _studentService = StudentService();
  final ParentService _parentService = ParentService();
  final SchoolService _schoolService = SchoolService();

  @override
  void initState() {
    super.initState();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un parent')));
      return;
    }
    if (_selectedLevelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un niveau')));
      return;
    }

    final rawdhaId = ref.watch(currentRawdhaIdProvider);
    if (rawdhaId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: ID Rawdha non trouvé')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Élève enregistré')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
      appBar: AppBar(title: Text(widget.student == null ? 'Nouvel Élève' : 'Modifier Élève')),
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
                    : const Text('Enregistrer', style: TextStyle(fontSize: 18)),
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
            const Text('Identité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person)),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
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
                    decoration: const InputDecoration(labelText: 'Sexe', prefixIcon: Icon(Icons.wc)),
                    items: const [
                      DropdownMenuItem(value: 'boy', child: Text('Garçon')),
                      DropdownMenuItem(value: 'girl', child: Text('Fille')),
                    ],
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date de naissance', prefixIcon: Icon(Icons.calendar_today)),
                      child: Text(
                        _birthdate != null 
                          ? DateFormat('dd/MM/yyyy').format(_birthdate!) 
                          : 'Choisir',
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
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';
    return StreamBuilder<List<SchoolLevelModel>>(
      stream: _schoolService.getLevels(rawdhaId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final levels = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scolarité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedLevelId,
                  decoration: const InputDecoration(labelText: 'Niveau', prefixIcon: Icon(Icons.school)),
                  items: levels.map((l) => DropdownMenuItem(
                    value: l.id, 
                    child: Text(context.locale.languageCode == 'ar' ? l.nameAr : l.nameFr),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedLevelId = v),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParentSelector() {
    final rawdhaId = ref.watch(currentRawdhaIdProvider) ?? '';
    return StreamBuilder<List<ParentModel>>(
      stream: _parentService.getParents(rawdhaId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final parents = snapshot.data!;
        
        // Improve with Autocomplete or Searchable Dropdown for large lists
        // For now simple dropdown
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Parent Responsable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedParentId,
                  decoration: const InputDecoration(labelText: 'Sélectionner le parent', prefixIcon: Icon(Icons.family_restroom)),
                  items: parents.map((p) => DropdownMenuItem(
                    value: p.id, 
                    child: Text('${p.firstName} ${p.lastName} (${p.phone})', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedParentId = v),
                  validator: (v) => v == null ? 'Requis' : null,
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
