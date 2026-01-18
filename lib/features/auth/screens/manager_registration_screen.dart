import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../services/manager_auth_service.dart';

class ManagerRegistrationScreen extends StatefulWidget {
  const ManagerRegistrationScreen({super.key});

  @override
  State<ManagerRegistrationScreen> createState() => _ManagerRegistrationScreenState();
}

class _ManagerRegistrationScreenState extends State<ManagerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rawdhaNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _rawdhaNameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ManagerAuthService();
      await authService.registerRawdha(
        rawdhaName: _rawdhaNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        adminUsername: _usernameController.text.trim(),
        adminPassword: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('manager.auth.success_msg'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(); // Retour au login
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
        title: Text('manager.auth.registration_title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'manager.auth.register_cta'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _rawdhaNameController,
                          decoration: InputDecoration(
                            labelText: 'manager.auth.rawdha_name'.tr(),
                            prefixIcon: const Icon(Icons.school),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'common.required'.tr() : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'manager.auth.phone_number'.tr(),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'common.required'.tr();
                            if (value.length < 8) return 'manager.auth.phone_invalid'.tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'manager.auth.admin_username'.tr(),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'common.required'.tr() : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'manager.auth.admin_password'.tr(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'common.required'.tr() : null,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegistration,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text('manager.auth.register_btn'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
