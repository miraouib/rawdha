import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/school_config_model.dart';
import '../../../services/school_service.dart';
import '../../auth/services/manager_auth_service.dart'; // Import
import 'package:go_router/go_router.dart'; // Import

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';

class SchoolConfigScreen extends ConsumerStatefulWidget {
  const SchoolConfigScreen({super.key});

  @override
  ConsumerState<SchoolConfigScreen> createState() => _SchoolConfigScreenState();
}

class _SchoolConfigScreenState extends ConsumerState<SchoolConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final SchoolService _schoolService = SchoolService();
  
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _logoUrlController; 
  late TextEditingController _schoolCodeController;

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
    _schoolCodeController = TextEditingController();
  }

  Future<void> _loadConfig() async {
    try {
      final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
      // Pour l'instant on utilise un stream mais on prend juste la première valeur pour le formulaire
      final stream = _schoolService.getSchoolConfig(rawdhaId);
      final config = await stream.first;
      
      if (mounted) {
        setState(() {
          _currentConfig = config;
          _nameController.text = config.name;
          _addressController.text = config.address ?? '';
          _phoneController.text = config.phone ?? '';
          _emailController.text = config.email ?? '';
          _logoUrlController.text = config.logoUrl ?? '';
          _schoolCodeController.text = config.schoolCode ?? '';
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
    _schoolCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
    
    try {
      final newConfig = SchoolConfigModel(
        rawdhaId: rawdhaId,
        id: 'main', // Toujours main
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        logoUrl: _logoUrlController.text.trim(),
        schoolCode: _schoolCodeController.text.trim().toUpperCase(),
      );
      
      await _schoolService.saveSchoolConfig(newConfig, rawdhaId);
      
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
                    _buildSectionHeader('school.info_general'.tr()),
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
                    
                    // School Code Field
                    TextFormField(
                      controller: _schoolCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Code École (Unique)',
                        prefixIcon: Icon(Icons.qr_code),
                        border: OutlineInputBorder(),
                        helperText: 'Ex: ISRAA - Requis pour connexion parents',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Code requis';
                        if (v.length < 3) return '3 caractères min.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader('school.contact'.tr()),
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
                    
                    _buildSectionHeader('school.branding'.tr()),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _logoUrlController,
                      decoration: InputDecoration(
                        labelText: 'school.fields.logo_url'.tr(),
                        prefixIcon: const Icon(Icons.image),
                        border: const OutlineInputBorder(),
                        helperText: 'school.logo_hint'.tr(),
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
                    
                    const SizedBox(height: 40),
                    _buildSectionHeader('Zone de Danger', color: Colors.red),
                    const SizedBox(height: 16),
                    
                    // Restore Data Button
                    Card(
                      elevation: 0,
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blue.shade200),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.history, color: Colors.blue),
                        title: const Text('Restaurer des données'),
                        subtitle: const Text('Récupérer d\'anciens élèves et parents'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.pushNamed('restore_data'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reset Data Button
                    Card(
                      elevation: 0,
                      color: Colors.red.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text('Réinitialiser l\'année scolaire'),
                        subtitle: const Text('Supprime tous les parents et élèves (Soft Delete)'),
                        onTap: _showResetConfirmation,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _showResetConfirmation() async {
    final passwordController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attention ! ⚠️'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cette action va archiver TOUS les parents et élèves actuels pour commencer une nouvelle année.\n\n'
              'Veuillez entrer votre mot de passe pour confirmer.'
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe Manager',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer Réinitialisation'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (passwordController.text.isEmpty) return;
      
      setState(() => _isLoading = true);
      final rawdhaId = ref.read(currentRawdhaIdProvider) ?? '';
      // We need manager ID implementation details which are usually in ManagerAuthService or Provider
      // Assuming we can skip managerAuth check here or find a way.
      // Ideally ref.read(currentManagerProvider)?.id
      
      // Let's instantiate auth service locally or use provider if available
      // Since we don't have easy access to managerID/password verification in this scope without refactoring AuthProvider heavily, 
      // I will implement a direct check or skip it for MVP request? 
      // User asked: "demande password user current if massword correct"
      
      // I'll need to instantiate ManagerAuthService and likely need the current Manager ID.
      // Let's try to get Manager ID from auth state if possible.
      // Assuming 'currentManagerIdProvider' exists or similar... 
      // checking 'rawdha_provider.dart' might reveal user info.
      
      final managerAuth = ManagerAuthService();
      // For now, assume we verify against currently logged in manager.
      // We need the manager ID.
      
      // WORKAROUND: Since I don't have the Manager ID easily accessible here without more reads, 
      // I will try to use the auth provider or pass.
      // Wait, 'currentManagerProvider' usually exists.
      
      try {
         final managerId = ref.read(currentManagerIdProvider);
         if (managerId == null) throw Exception("Manager non identifié");

         final isValid = await managerAuth.verifyPassword(managerId, passwordController.text);
         if (!isValid) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mot de passe incorrect ❌'), backgroundColor: Colors.red),
              );
              setState(() => _isLoading = false);
            }
            return;
         }

         // Password OK, Reset Data
         await _schoolService.resetSchoolData(rawdhaId);
         
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Année réinitialisée avec succès 🚀'), backgroundColor: Colors.green),
           );
         }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erreur: $e')),
           );
         }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSectionHeader(String title, {Color color = AppTheme.primaryBlue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: color
          )
        ),
        Divider(color: color.withOpacity(0.5)),
      ],
    );
  }
}
