import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/role_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp();
  
  // Initialiser les traductions
  await EasyLocalization.ensureInitialized();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('fr'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      child: const ProviderScope(
        child: RawdhaApp(),
      ),
    ),
  );
}

class RawdhaApp extends StatelessWidget {
  const RawdhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_name'.tr(),
      debugShowCheckedModeBanner: false,
      
      // Localisation
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      
      // Thème
      theme: AppTheme.lightTheme,
      
      // Page d'accueil
      home: const RoleSelectionScreen(),
    );
  }
}
