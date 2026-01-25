import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/parent_service.dart';
import '../../../services/session_service.dart';
import '../../../models/parent_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/rawdha_provider.dart';
import '../../../core/widgets/offline_wrapper.dart';

class ParentLoginScreen extends ConsumerStatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  ConsumerState<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends ConsumerState<ParentLoginScreen> {
  final _schoolCodeController = TextEditingController();
  final _idController = TextEditingController();
  final _parentService = ParentService();
  final _sessionService = SessionService();
  bool _isLoading = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);
    final creds = await _sessionService.getSavedCredentials();
    if (creds['schoolCode'] != null) _schoolCodeController.text = creds['schoolCode']!;
    if (creds['familyCode'] != null) _idController.text = creds['familyCode']!;
    final result = await _sessionService.tryAutoLogin();
    if (result is ParentModel && mounted) {
      ref.read(currentRawdhaIdProvider.notifier).state = result.rawdhaId;
      context.goNamed('parent_dashboard', extra: result);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _schoolCodeController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final schoolCode = _schoolCodeController.text.trim().toUpperCase();
    final familyCode = _idController.text.trim().toUpperCase();
    if (schoolCode.isEmpty || familyCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('common.error'.tr()), backgroundColor: AppTheme.errorRed),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final parent = await _parentService.loginParent(schoolCode, familyCode);
      if (parent != null) {
        if (_rememberMe) await _sessionService.saveSession(schoolCode, familyCode, parent.rawdhaId);
        if (mounted) {
          ref.read(currentRawdhaIdProvider.notifier).state = parent.rawdhaId;
          context.goNamed('parent_dashboard', extra: parent);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('parent.invalid_credentials'.tr()), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OfflineWrapper(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppTheme.parentGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.gradientCardShadow,
                    ),
                    child: const Icon(Icons.family_restroom, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  Text('parent.title'.tr(), style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 8),
                  Text('parent.enter_code'.tr(), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textGray)),
                  const SizedBox(height: 48),
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
                          controller: _schoolCodeController,
                          decoration: InputDecoration(
                            labelText: 'parent.school_code_label'.tr(),
                            prefixIcon: const Icon(Icons.school_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            hintText: 'parent.school_code_hint'.tr(),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _idController,
                          decoration: InputDecoration(
                            labelText: 'parent.family_id_label'.tr(),
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: AppTheme.accentPink,
                              onChanged: (v) => setState(() => _rememberMe = v ?? true),
                            ),
                            Text('parent.remember_me'.tr(), style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentPink,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text('parent.login_button'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentPink.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.accentPink, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'parent.ask_school_code'.tr(),
                            style: const TextStyle(fontSize: 12, color: AppTheme.accentPink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
