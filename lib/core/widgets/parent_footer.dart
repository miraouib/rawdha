import 'package:flutter/material.dart';

class ParentFooter extends StatelessWidget {
  const ParentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.school, size: 40, color: Colors.blue),
            ),
          ),
        ),
      ),
    );
  }
}
