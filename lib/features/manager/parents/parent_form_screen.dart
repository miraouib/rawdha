import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/parent_model.dart';
import '../../../services/parent_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../core/helpers/validator_helper.dart';

class ParentFormScreen extends ConsumerStatefulWidget {
  final ParentModel? parent;

  const ParentFormScreen({super.key, this.parent});

  @override
  ConsumerState<ParentFormScreen> createState() => _ParentFormScreenState();
}

class _ParentFormScreenState extends ConsumerState<ParentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _spouseNameController = TextEditingController();
  final _spousePhoneController = TextEditingController();
  final _monthlyFeeController = TextEditingController();
  
  String? _familyCode;
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
    } else {
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

    final rawdhaId = ref.watch(currentRawdhaIdProvider);
    if (rawdhaId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('parent.error_rawdha_id'.tr())));
      }
      return;
    }

    try {
      final parent = ParentModel(
        rawdhaId: rawdhaId,
        id: widget.parent?.id ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        spouseName: _spouseNameController.text.trim(),
        spousePhone: _spousePhoneController.text.trim(),
        monthlyFee: _monthlyFeeController.text.isNotEmpty ? double.tryParse(_monthlyFeeController.text.trim()) : null,
        familyCode: _familyCode!,
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
          SnackBar(content: Text('common.error'.tr() + ': $e')),
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
        title: Text(isEditing ? 'parent.edit_parent'.tr() : 'parent.add_parent'.tr()),
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
                      Text('parent.generated_codes'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CodeDisplay(label: 'parent.family_code_label'.tr(), code: _familyCode ?? '...'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'parent.note_codes'.tr(),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'parent.first_name'.tr(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) => value == null || value.isEmpty ? 'common.required'.tr() : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'parent.last_name'.tr(),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.isEmpty ? 'common.required'.tr() : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: ValidatorHelper.phoneFormatters(),
                decoration: InputDecoration(
                  labelText: 'parent.phone'.tr(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: ValidatorHelper.phoneValidator,
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
              Text('parent.spouse_section'.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _spouseNameController,
                decoration: InputDecoration(
                  labelText: 'parent.spouse_name'.tr(),
                  prefixIcon: const Icon(Icons.person_add),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _spousePhoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: ValidatorHelper.phoneFormatters(),
                decoration: InputDecoration(
                  labelText: 'parent.spouse_phone'.tr(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    return ValidatorHelper.phoneValidator(value);
                  }
                  return null;
                },
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
                    : Text('parent.save_button'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
