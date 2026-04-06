import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/presentation/viewmodels/auth/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

enum SnackType { success, error }

void showAppSnackBar(
  BuildContext context, {
  required String message,
  required SnackType type,
}) {
  final isSuccess = type == SnackType.success;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      duration: const Duration(seconds: 3),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSuccess ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
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
              child: Icon(
                isSuccess ? Icons.check_rounded : Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
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

Future<void> runWithFeedback(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action, {
  required NotifierProvider<BoolNotifier, bool> loadingProvider,
  String? successMessage,
  VoidCallback? onSuccess,
}) async {
  //on active le spinner avant de lancer l'action
  ref.read(loadingProvider.notifier).setValue(true);
  try {
    await action();

    //on arrete le spinner tout de suite apres l'action et AVANT la navigation
    //parce que si on navigue d'abord le widget est detruit et setValue plante
    try {
      ref.read(loadingProvider.notifier).setValue(false);
    } catch (_) {}

    if (context.mounted) {
      if (successMessage != null) {
        showAppSnackBar(context, message: successMessage, type: SnackType.success);
      }
      onSuccess?.call();
    }
  } catch (e) {
    //meme chose en cas d'erreur, on arrete toujours le spinner
    try {
      ref.read(loadingProvider.notifier).setValue(false);
    } catch (_) {}

    if (context.mounted) {
      showAppSnackBar(context, message: e.toString(), type: SnackType.error);
    }
  }
}

class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(googleLoadingProvider);

    return OutlinedButton(
onPressed: isLoading
    ? null
    : () => runWithFeedback(
          context,
          ref,
          () => ref.read(authProvider.notifier).signInWithGoogle(),
          loadingProvider: googleLoadingProvider,
          onSuccess: () => context.go('/home'),
        ),
      style: OutlinedButton.styleFrom(
        fixedSize: const Size(double.infinity, 56),
        minimumSize: const Size(double.infinity, 56),
        maximumSize: const Size(double.infinity, 56),
        side: BorderSide(
          color: isLoading ? Colors.grey.shade300 : const Color(0xFFD9D9D9),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: isLoading
                ? CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  )
                : SvgPicture.asset(
                    'assets/icones/google_icon.svg',
                    height: 24,
                  ),
          ),
          AppSpacing.hMedium,
          Text(
            isLoading ? 'Connexion...' : 'Continuer avec Google',
            style: AppTextStyles.body.copyWith(
              color: isLoading ? Colors.grey : AppColors.blackB,
            ),
          ),
        ],
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: AppTextStyles.caption.copyWith(color: Colors.grey),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
      ],
    );
  }
}