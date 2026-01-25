import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/school_config_model.dart';
import '../../../services/school_service.dart';
import '../../auth/services/manager_auth_service.dart'; // Import
import 'package:go_router/go_router.dart'; // Import
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../services/storage_service.dart';
import '../../../services/session_service.dart';
import '../../../core/encryption/encryption_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../core/widgets/manager_footer.dart';

class SchoolConfigScreen extends ConsumerStatefulWidget {
  const SchoolConfigScreen({super.key});

  @override
  ConsumerState<SchoolConfigScreen> createState() => _SchoolConfigScreenState();
}

class _SchoolConfigScreenState extends ConsumerState<SchoolConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _logoUrlController; 
  late TextEditingController _schoolCodeController;

  final SchoolService _schoolService = SchoolService();
  bool _isLoading = true;
  SchoolConfigModel? _currentConfig;
  int _selectedStartMonth = 9;
  bool _restrictDevices = false;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _logoUrlController = TextEditingController();
    _schoolCodeController = TextEditingController();
    
    // Add listener for auto-generation
    _nameController.addListener(_onNameChanged);
    
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }

  void _onNameChanged() {
    final name = _nameController.text.trim();
    final currentCode = _schoolCodeController.text.trim();
    
    // Auto-generate if code is empty (User hasn't manually edited the code).
    if (name.isNotEmpty && currentCode.isEmpty) {
      final generated = _generateCodeFromName(name);
      _schoolCodeController.text = generated;
    }
  }

  String _generateCodeFromName(String name) {
    if (name.isEmpty) return '';
    
    // Normalize spaces
    final words = name.trim().split(RegExp(r'\s+'));
    String code = '';

    if (words.length == 1) {
      // 1 Word: Take the whole word
      code = words[0]; 
    } else if (words.length == 2) {
      // 2 Words: 3 first chars of each
      code = words.map((w) => w.length >= 3 ? w.substring(0, 3) : w).join();
    } else {
      // > 2 Words: 2 first chars of each
      code = words.map((w) => w.length >= 2 ? w.substring(0, 2) : w).join();
    }

    return code.toUpperCase();
  }
  
  Future<void> _pickAndUploadLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;
    
    final file = File(image.path);
    final size = await file.length();
    
    if (size > 350 * 1024) { // 350 KB
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('school.logo_too_large'.tr())),
        );
      }
      return;
    }
    
    if (_nameController.text.isEmpty) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('school.enter_name_first'.tr())),
        );
      }
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final storageService = StorageService();
      final url = await storageService.uploadSchoolLogo(file, _nameController.text);
      
      setState(() {
        _logoUrlController.text = url;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('school.logo_uploaded'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${"school.upload_error".tr()}: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadConfig([String? specificId]) async {
    try {
      final rawdhaId = specificId ?? ref.read(currentRawdhaIdProvider) ?? '';
      
      if (rawdhaId.isEmpty) return;

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
          _selectedStartMonth = config.paymentStartMonth;
          _restrictDevices = config.restrictDevices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${"school.load_error".tr()}: $e')),
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
    final code = _schoolCodeController.text.trim().toUpperCase();
    
    // Check if code is unique
    try {
      final exists = await _schoolService.checkSchoolCodeExists(code, rawdhaId);
      if (exists) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('school.code_taken'.tr(namedArgs: {'code': code}))),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${"school.code_check_error".tr()}: $e')),
        );
      }
      return;
    }
    
    try {
      // Use existing ID if available to avoid duplicates (older docs might have auto-generated IDs)
      final docId = (_currentConfig?.id != null && _currentConfig!.id != 'default') 
          ? _currentConfig!.id 
          : rawdhaId;

      final newConfig = SchoolConfigModel(
        rawdhaId: rawdhaId,
        id: docId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        logoUrl: _logoUrlController.text.trim(),
        schoolCode: _schoolCodeController.text.trim().toUpperCase(),
        paymentStartMonth: _selectedStartMonth,
        restrictDevices: _restrictDevices,
      );
      
      await _schoolService.saveSchoolConfig(newConfig, rawdhaId);
      
      // If restriction is enabled, ensure only the current device is authorized for this manager
      if (_restrictDevices) {
        final managerId = ref.read(currentManagerIdProvider);
        if (managerId != null) {
          final managerAuth = ManagerAuthService();
          await managerAuth.restrictToCurrentDevice(managerId);
        }
      }
      
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
          SnackBar(content: Text('${"common.error".tr()}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentRawdhaIdProvider, (previous, next) {
      if (next != null && next.isNotEmpty && next != previous) {
        _loadConfig(next);
      }
    });

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
                      decoration: InputDecoration(
                        labelText: 'school.fields.code'.tr(),
                        prefixIcon: const Icon(Icons.qr_code),
                        border: const OutlineInputBorder(),
                        helperText: 'school.fields.code_hint'.tr(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'school.validation.code_required'.tr();
                        if (v.length < 3) return 'school.validation.code_min_length'.tr();
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('school.payment_config'.tr()),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<int>(
                      value: _selectedStartMonth,
                      decoration: InputDecoration(
                        labelText: 'school.payment_start_month'.tr(),
                        prefixIcon: const Icon(Icons.calendar_month),
                        border: const OutlineInputBorder(),
                        helperText: 'school.payment_start_month_hint'.tr(),
                      ),
                      items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(DateFormat('MMMM', context.locale.languageCode).format(DateTime(2022, m))),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedStartMonth = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: Text('school.restrict_devices'.tr()),
                      subtitle: Text('school.restrict_devices_hint'.tr()),
                      value: _restrictDevices,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (v) => setState(() => _restrictDevices = v),
                    ),
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
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _logoUrlController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'school.fields.logo_url'.tr(),
                              prefixIcon: const Icon(Icons.image),
                              border: const OutlineInputBorder(),
                              helperText: 'school.logo_hint'.tr(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            IconButton.filled(
                              onPressed: _pickAndUploadLogo,
                              icon: const Icon(Icons.upload_file),
                              tooltip: 'school.upload_logo_tooltip'.tr(),
                            ),
                            Text('school.max_size'.tr(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    if (_logoUrlController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _logoUrlController.text,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                              ),
                            ),
                          ),
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
                    
                       const SizedBox(height: 16),
                      _buildSectionHeader('manager.security'.tr()),
                      const SizedBox(height: 16),
                      
                      Card(
                        elevation: 0,
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.lock_outline, color: Colors.blue),
                          title: Text('manager.change_password'.tr()),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _showChangePasswordDialog,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      _buildSectionHeader('school.danger_zone'.tr(), color: Colors.red),
                      const SizedBox(height: 16),
                      
                      // Restore Data Button
                      Card(
                        elevation: 0,
                        color: Colors.green.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.green.shade200),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.history, color: Colors.green),
                          title: Text('school.restore_data'.tr()),
                          subtitle: Text('school.restore_data_desc'.tr()),
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
                          title: Text('school.reset_year'.tr()),
                          subtitle: Text('school.reset_year_desc'.tr()),
                          onTap: _showResetConfirmation,
                        ),
                      ),
                       
                       const SizedBox(height: 16),
                      _buildSessionCard(),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: const ManagerFooter(),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('manager.change_password'.tr()),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'manager.current_password'.tr(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'common.required'.tr() : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'manager.new_password'.tr(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'common.required'.tr();
                      if (v.length < 6) return 'manager.password_too_short'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'manager.confirm_password'.tr(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != newPasswordController.text) return 'manager.passwords_not_match'.tr();
                      return null;
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final managerId = ref.read(currentManagerIdProvider);
                if (managerId == null) return;

                Navigator.pop(context); // Close dialog first
                setState(() => _isLoading = true);

                try {
                  final authService = ManagerAuthService();
                  // 1. Verify current password
                  final isValid = await authService.verifyPassword(managerId, currentPasswordController.text);
                  if (!isValid) {
                    throw Exception('manager.auth.password_incorrect'.tr());
                  }

                  // 2. Update password in Firestore
                  await authService.updatePassword(managerId, newPasswordController.text);

                  // 3. Update SharedPreferences if "remember me" was used
                  final prefs = await SharedPreferences.getInstance();
                  final rememberMe = prefs.getBool('remember_me') ?? false;
                  if (rememberMe) {
                    final encryptedPass = EncryptionService().encryptString(newPasswordController.text);
                    await prefs.setString('remember_password_enc', encryptedPass);
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('manager.auth.password_changed'.tr()), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: Text('common.save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for session card
  Widget _buildSessionCard() {
    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: Text('logout'.tr(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        onTap: _showLogoutConfirmation,
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('logout_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
       await SessionService().clearSession(); // Clear persistent session
       ref.read(currentRawdhaIdProvider.notifier).state = null;
       ref.read(currentManagerIdProvider.notifier).state = null;
       ref.read(currentManagerUsernameProvider.notifier).state = null;
       context.go('/'); 
    }
  }

  Future<void> _showResetConfirmation() async {
    final passwordController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('school.reset_warning_title'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('school.reset_warning_desc'.tr()),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'manager.password'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('school.confirm_reset'.tr()),
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
         if (managerId == null) throw Exception("manager.auth.not_found".tr());

         final isValid = await managerAuth.verifyPassword(managerId, passwordController.text);
         if (!isValid) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('manager.auth.password_incorrect'.tr()), backgroundColor: Colors.red),
              );
              setState(() => _isLoading = false);
            }
            return;
         }

         // Password OK, Reset Data
         await _schoolService.resetSchoolData(rawdhaId);
         
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('school.reset_success'.tr()), backgroundColor: Colors.green),
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
