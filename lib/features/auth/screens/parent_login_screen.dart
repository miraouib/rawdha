import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';

/// Écran de connexion Parent
/// 
/// Authentification simple avec code unique (6 chiffres)
class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final code = _codeController.text.trim();
    
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Le code doit contenir 6 chiffres'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Implémenter la logique de connexion
    // 1. Rechercher le parent avec ce code (chiffré)
    // 2. Si trouvé, récupérer les enfants
    // 3. Naviguer vers la liste des enfants

    await Future.delayed(const Duration(seconds: 2)); // Simulation

    if (mounted) {
      setState(() => _isLoading = false);
      
      // Afficher un message de succès (temporaire)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connexion réussie! (À implémenter)'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône Parent
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppTheme.parentGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.gradientCardShadow,
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Titre
                Text(
                  'parent.title'.tr(),
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'parent.enter_code'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Carte de saisie du code
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      // Champ de code
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'parent.code_placeholder'.tr(),
                          hintStyle: TextStyle(
                            color: AppTheme.textLight,
                            letterSpacing: 8,
                          ),
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Bouton de connexion
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentPink,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('parent.login_button'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentPink.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.accentPink,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Demandez votre code unique à l\'école',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentPink,
                          ),
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
    );
  }
}
