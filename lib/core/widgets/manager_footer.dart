import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class ManagerFooter extends StatelessWidget {
  const ManagerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            
            // Center: Version info
            Text(
              'v0.0.1+1',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textLight,
                letterSpacing: 0.5,
              ),
            ),

            const Spacer(),
const Spacer(),
            // Left (Start): Logo & App Name
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
                
              ],
            ),
            
            const Spacer(),

            // Right (End): Contact Link
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.pushNamed('contact_developer'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        'school.developer.title'.tr(),
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
