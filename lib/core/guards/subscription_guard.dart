import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rawdha_provider.dart';
import '../../models/rawdha_model.dart';

enum SubscriptionStatus {
  active,
  notAccepted,
  expired,
}

class SubscriptionGuard extends ConsumerWidget {
  final Widget child;
  final bool isParent;

  const SubscriptionGuard({
    super.key,
    required this.child,
    this.isParent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawdhaAsync = ref.watch(currentRawdhaProvider);

    return rawdhaAsync.when(
      data: (rawdha) {
        if (rawdha == null) return child; // Should not happen if logged in

        if (isParent) {
          if (!rawdha.accepter) {
            return _buildLockedScreen(
              context,
              'Accès Parent Désactivé',
              'Votre établissement n\'a pas encore été accepté par l\'administrateur.',
            );
          }
          // Expired is okay for parents according to rules
          return child;
        } else {
          // Manager Logic
          if (!rawdha.accepter) {
            return _buildRestrictedScreen(
              context,
              rawdha,
              child,
              'Établissement Non Validé',
              'Votre compte est en attente de validation. Les fonctionnalités sont désactivées.',
            );
          }

          if (!rawdha.isSubscriptionActive) {
            return _buildLockedScreen(
              context,
              'Abonnement Expiré',
              'Votre abonnement a expiré. Vous ne pouvez plus modifier de données.',
              isReadOnly: true,
              child: child,
            );
          }

          return child;
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }

  Widget _buildRestrictedScreen(
    BuildContext context,
    RawdhaModel rawdha,
    Widget child,
    String title,
    String message,
  ) {
    return Scaffold(
      body: Stack(
        children: [
          // The actual dashboard, but greyscale and non-interactive
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: AbsorbPointer(
              absorbing: true,
              child: child,
            ),
          ),
          // Overlay warning
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hourglass_empty, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                message,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // Logout logic should still work
                        // Since we are in AbsorbPointer for the child, 
                        // this button outside of it works.
                        context.go('/');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedScreen(
    BuildContext context,
    String title,
    String message, {
    bool isLimited = false,
    bool isReadOnly = false,
    Widget? child,
  }) {
    // Keep original implementation for expired or other locks if needed
    // or just use Restricted for everything.
    // Let's keep it for now as it's used for isReadOnly (expired)
    if (isReadOnly) {
       return Scaffold(
        body: Stack(
          children: [
            if (child != null) 
              child,
            Container(
              color: Colors.black.withOpacity(0.3),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(20),
              child: Card(
                color: Colors.red.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
