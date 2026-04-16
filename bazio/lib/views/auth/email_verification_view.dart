import 'package:bazio/core/components/button_text.dart';
import 'package:bazio/core/components/custom_app_bar.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/utils/auth_helpers.dart';
import 'package:bazio/viewmodels/auth/email_verification_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmailVerificationView extends ConsumerStatefulWidget {
  final String email;
  const EmailVerificationView({super.key, required this.email});

  @override
  ConsumerState<EmailVerificationView> createState() =>
      _EmailVerificationViewState();
}

class _EmailVerificationViewState extends ConsumerState<EmailVerificationView>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    //on ajoute l'observeur pour surveiller quand l'utilisateur quitte/revient sur l'app
    WidgetsBinding.instance.addObserver(this);

    //on lance le polling juste apres le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emailVerificationProvider.notifier).startPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  //on force un check manuel dès que l'app revient au premier plan
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(emailVerificationProvider.notifier).checkVerification();
    }
  }

  //on supprime le compte et on retourne a l'inscription si l'utilisateur annule
  Future<void> _cancelAndGoBack() async {
    await ref.read(emailVerificationProvider.notifier).cancelAndDelete();
    if (mounted) context.go('/register');
  }

  //logique de renvoi avec feedback par snackbar
  Future<void> _resendEmail() async {
    final error =
        await ref.read(emailVerificationProvider.notifier).resendEmail();
    if (!mounted) return;
    if (error != null) {
      showAppSnackBar(context, message: error, type: SnackType.error);
    } else {
      showAppSnackBar(
        context,
        message: 'Email renvoyé à ${widget.email}',
        type: SnackType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailVerificationProvider);

    //on ecoute le changement d'etat pour rediriger automatiquement vers le login
    ref.listen<VerificationState>(emailVerificationProvider, (_, next) {
      if (next.verified && mounted) {
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: PopScope(
        canPop: false,//on empeche le retour arriere swipe/bouton systeme sans passer par notre bouton
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!state.verified)
                  CustomAppBar(
                    title: 'Vérification',
                    onBack: _cancelAndGoBack,
                  ),

                Expanded(
                  child: state.verified
                      ? _buildVerifiedState()
                      : _buildWaitingState(state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //vue affichee une fois que le lien a ete valide
  Widget _buildVerifiedState() {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: Colors.green,
          ),
        ),
        AppSpacing.vExtraLarge,
        Text(
          'Email vérifié !',
          style: AppTextStyles.h2.copyWith(color: Colors.green),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vMedium,
        Text(
          'Votre compte a été créé avec succès.\nVous pouvez maintenant vous connecter.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.blackO),
        ),
        const Spacer(),
        AppButton(
          text: 'Se connecter',
          onPressed: () => context.go('/login'),
        ),
        AppSpacing.vLarge,
      ],
    );
  }

  //vue d'attente avec les instructions et le bouton de renvoi
  Widget _buildWaitingState(VerificationState state) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_unread_outlined,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        AppSpacing.vExtraLarge,
        Text(
          'Vérifiez votre email',
          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vMedium,
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.body.copyWith(color: AppColors.blackO),
            children: [
              const TextSpan(text: 'Un lien de vérification a été envoyé à\n'),
              TextSpan(
                text: widget.email,
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
              ),
              const TextSpan(
                text:
                    '\n\nCliquez sur le lien dans l\'email puis revenez dans l\'application.',
              ),
            ],
          ),
        ),
        const Spacer(),
        //petit indicateur visuel pour dire que l'app travaille en arriere-plan
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'En attente de vérification...',
              style: AppTextStyles.body.copyWith(color: AppColors.blackO),
            ),
          ],
        ),
        AppSpacing.vExtraLarge,
        GestureDetector(
          onTap: (state.isResending || state.resendCooldown > 0)
              ? null
              : _resendEmail,
          child: state.isResending
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Text(
                  state.resendCooldown > 0
                      ? 'Renvoyer dans ${state.resendCooldown}s'
                      : 'Renvoyer l\'email',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: state.resendCooldown > 0
                        ? Colors.grey
                        : AppColors.primary,
                  ),
                ),
        ),
        AppSpacing.vLarge,
      ],
    );
  }
}