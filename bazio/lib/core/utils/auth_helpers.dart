import 'package:bazio/core/components/app_snack_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/auth/auth_ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

//on exporte pour que les vues n'aient pas a importer app_snack_bar separement
export 'package:bazio/core/components/app_snack_bar.dart'
    show AppSnackBar, SnackType, humanizeError;

//un petit raccourci pour afficher nos barres de message
void showAppSnackBar(
  BuildContext context, {
  required String message,
  required SnackType type,
}) {
  AppSnackBar.show(context, message: message, type: type);
}

//la grosse fonction qui gere tout : loading, erreurs et succes d'une action
Future<void> runWithFeedback(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action, {
  required NotifierProvider<BoolNotifier, bool> loadingProvider,
  String? successMessage,
  VoidCallback? onSuccess,
}) async {
  ref.read(loadingProvider.notifier).setValue(true);//on active le spinner

  try {
    await action();
  } catch (e) {
    ref.read(loadingProvider.notifier).setValue(false);

    //si l'utilisateur a juste annule (ex: pop up google fermee), on stop
    if (e.toString() == 'cancelled') return;

    if (context.mounted) {
      AppSnackBar.showError(context, e);//on affiche l'erreur en rouge
    }
    return;
  }

  ref.read(loadingProvider.notifier).setValue(false);//action finie

  if (context.mounted) {
    if (successMessage != null) {
      showAppSnackBar(context, message: successMessage, type: SnackType.success);
    }
    onSuccess?.call();
  }
}

//le bouton standard pour se connecter avec son compte Google
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

//le separateur horizontal pour l'alternative entre email et google
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