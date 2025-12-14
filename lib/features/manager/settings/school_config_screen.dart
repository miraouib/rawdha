import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/school_config_model.dart';
import '../../../services/school_service.dart';

class SchoolConfigScreen extends StatefulWidget {
  const SchoolConfigScreen({super.key});

  @override
  State<SchoolConfigScreen> createState() => _SchoolConfigScreenState();
}

class _SchoolConfigScreenState extends State<SchoolConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final SchoolService _schoolService = SchoolService();
  
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _logoUrlController; 
  late TextEditingController _regNumberController;

  bool _isLoading = true;
  SchoolConfigModel? _currentConfig;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadConfig();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _logoUrlController = TextEditingController();
    _regNumberController = TextEditingController();
  }

  Future<void> _loadConfig() async {
    try {
      // Pour l'instant on utilise un stream mais on prend juste la première valeur pour le formulaire
      final stream = _schoolService.getSchoolConfig();
      final config = await stream.first;
      
      if (mounted) {
        setState(() {
          _currentConfig = config;
          _nameController.text = config.name;
          _addressController.text = config.address ?? '';
          _addressController.text = config.address ?? '';
          _phoneController.text = config.phone ?? '';
          _emailController.text = config.email ?? '';
          _logoUrlController.text = config.logoUrl ?? '';
          _regNumberController.text = config.registrationNumber ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _logoUrlController.dispose();
    _regNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newConfig = SchoolConfigModel(
        id: 'main', // Toujours main
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        logoUrl: _logoUrlController.text.trim(),
        registrationNumber: _regNumberController.text.trim(),
      );
      
      await _schoolService.saveSchoolConfig(newConfig);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('school.configuration'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Informations Générales'),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'school.fields.name'.tr(),
                        prefixIcon: const Icon(Icons.school),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'school.fields.name'.tr() + ' ' + 'common.required'.tr() : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _regNumberController,
                      decoration: InputDecoration(
                        labelText: 'school.fields.reg_number'.tr(),
                        prefixIcon: const Icon(Icons.confirmation_number),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader('Contact'),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'school.fields.address'.tr(),
                        prefixIcon: const Icon(Icons.location_on),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'school.fields.phone'.tr(),
                        prefixIcon: const Icon(Icons.phone),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'school.fields.email'.tr(),
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader('Branding'),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _logoUrlController,
                      decoration: InputDecoration(
                        labelText: 'school.fields.logo_url'.tr(),
                        prefixIcon: const Icon(Icons.image),
                        border: const OutlineInputBorder(),
                        helperText: 'Lien vers une image en ligne',
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('common.save'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, 
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: AppTheme.primaryBlue
          )
        ),
        const Divider(),
      ],
    );
  }
}
