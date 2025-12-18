import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/parent_model.dart';
import '../../../services/parent_service.dart';

class ParentFormScreen extends StatefulWidget {
  final ParentModel? parent;

  const ParentFormScreen({super.key, this.parent});

  @override
  State<ParentFormScreen> createState() => _ParentFormScreenState();
}

class _ParentFormScreenState extends State<ParentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _spouseNameController = TextEditingController();
  final _spousePhoneController = TextEditingController();
  final _monthlyFeeController = TextEditingController();
  
  String? _familyCode;
  String? _accessCode;
  bool _isLoading = false;
  final ParentService _parentService = ParentService();

  @override
  void initState() {
    super.initState();
    if (widget.parent != null) {
      _firstNameController.text = widget.parent!.firstName;
      _lastNameController.text = widget.parent!.lastName;
      _phoneController.text = widget.parent!.phone;
      _spouseNameController.text = widget.parent!.spouseName;
      _spousePhoneController.text = widget.parent!.spousePhone;
      
      if (widget.parent!.monthlyFee != null) {
        _monthlyFeeController.text = widget.parent!.monthlyFee.toString();
      }
      
      _familyCode = widget.parent!.familyCode;
      _accessCode = widget.parent!.accessCode;
    } else {
      _accessCode = _parentService.generateAccessCode();
      _familyCode = '...';
    }

    _firstNameController.addListener(_updateFamilyCode);
  }

  void _updateFamilyCode() {
    if (widget.parent == null) {
      setState(() {
        _familyCode = _parentService.generateFamilyCode(_firstNameController.text);
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _spouseNameController.dispose();
    _spousePhoneController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  Future<void> _saveParent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final parent = ParentModel(
        id: widget.parent?.id ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        spouseName: _spouseNameController.text.trim(),
        spousePhone: _spousePhoneController.text.trim(),
        monthlyFee: _monthlyFeeController.text.isNotEmpty ? double.tryParse(_monthlyFeeController.text.trim()) : null,
        familyCode: _familyCode!,
        accessCode: _accessCode!,
        studentIds: widget.parent?.studentIds ?? [],
        createdAt: widget.parent?.createdAt ?? DateTime.now(),
      );

      if (widget.parent == null) {
        await _parentService.addParent(parent);
      } else {
        await _parentService.updateParent(parent);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.parent != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Parent' : 'Ajouter Parent'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.blue.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Codes d\'accès (Générés)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CodeDisplay(label: 'Code Famille', code: _familyCode ?? '...'),
                          _CodeDisplay(label: 'Code PIN', code: _accessCode ?? '...'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Notez ces codes pour le parent.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _monthlyFeeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'parent.monthly_fee_label'.tr(),
                  prefixIcon: const Icon(Icons.monetization_on),
                ),
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 32),
              const Text('Conjoint (Optionnel)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _spouseNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du conjoint',
                  prefixIcon: Icon(Icons.person_add),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _spousePhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone conjoint',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),

              SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveParent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enregistrer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

class _CodeDisplay extends StatelessWidget {
  final String label;
  final String code;

  const _CodeDisplay({required this.label, required this.code});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            code,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
      ],
    );
  }
}
