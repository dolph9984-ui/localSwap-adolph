import 'package:flutter/material.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/utils/error_helpers.dart';

export 'package:bazio/core/utils/error_helpers.dart' show humanizeError;

// Les différents types de snacks possibles
enum SnackType { success, error, info }

// Le composant pour afficher les petites barres de message
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    required SnackType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (message.isEmpty) return;

    final isSuccess = type == SnackType.success;
    final isInfo = type == SnackType.info;

    // On définit la couleur selon le type d'alerte
    final Color bgColor = isSuccess
        ? const Color(0xFF1B5E20)
        : isInfo
            ? AppColors.primary
            : const Color(0xFFB71C1C);

    final IconData icon = isSuccess
        ? Icons.check_rounded
        : isInfo
            ? Icons.info_outline_rounded
            : Icons.error_outline_rounded;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Le petit raccourci pour balancer une erreur direct
  static void showError(BuildContext context, dynamic error) {
    final message = humanizeError(error);
    if (message.isEmpty) return;
    show(context, message: message, type: SnackType.error);
  }
}

// Le widget qu'on affiche quand un chargement async foire
class AppErrorWidget extends StatelessWidget {
  final String message;
  const AppErrorWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message.isNotEmpty
                  ? message
                  : 'Une erreur inattendue est survenue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
