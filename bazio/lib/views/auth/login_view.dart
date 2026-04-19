import 'package:bazio/core/components/app_button.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/components/input_decoration.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/components/auth_helpers.dart';
import 'package:bazio/viewmodels/auth/auth_notifier.dart';
import 'package:bazio/viewmodels/auth/auth_ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    
    //on ecoute les changements pour activer le bouton de connexion
    _emailController.addListener(_updateFormState);
    _passwordController.addListener(_updateFormState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //on reset le loading au cas ou
      ref.read(loginLoadingProvider.notifier).setValue(false);

      //affiche le message de succes venant de EmailVerificationView si besoin
      final msg = ref.read(successMessageProvider);
      if (msg != null) {
        showAppSnackBar(context, message: msg, type: SnackType.success);
        ref.read(successMessageProvider.notifier).set(null);
      }
    });
  }

  //on verifie simplement si les champs ne sont pas vides pour le bouton
  void _updateFormState() {
    ref.read(loginFormValidProvider.notifier).setValue(
          _emailController.text.trim().isNotEmpty &&
              _passwordController.text.trim().isNotEmpty,
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isObscured = ref.watch(obscureLoginPasswordProvider);
    final isFormValid = ref.watch(loginFormValidProvider);
    final isLoading = ref.watch(loginLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          child: Column(
            children: [
              Text('Connexion',
                  style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
              AppSpacing.vMedium,
              Text(
                'On est contents de vous \nrevoir!',
                textAlign: TextAlign.center,
                style: AppTextStyles.h3.copyWith(color: AppColors.blackO),
              ),
              AppSpacing.vExtraLarge,

              //champ email
              TextFormField(
                controller: _emailController,
                style: AppTextStyles.body,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: AppInputDecoration.defaultStyle(
                  hint: 'Entrez votre adresse mail',
                  label: 'Adresse mail',
                ),
              ),
              AppSpacing.vLarge,

              //champ mot de passe
              TextFormField(
                controller: _passwordController,
                obscureText: isObscured,
                obscuringCharacter: '●',
                style: AppTextStyles.body,
                textInputAction: TextInputAction.done,
                decoration: AppInputDecoration.defaultStyle(
                  hint: '●●●●●●●●●●',
                  label: 'Mot de passe',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        ref.read(obscureLoginPasswordProvider.notifier).toggle(),
                    icon: SvgPicture.asset(
                      isObscured
                          ? 'assets/icones/eye_close.svg'
                          : 'assets/icones/eye_open.svg',
                      width: 24,
                      colorFilter:
                          const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              AppSpacing.vExtraLarge,

              //bouton de connexion principale
              AppButton(
                text: 'Se Connecter',
                isLoading: isLoading,
                onPressed: (isFormValid && !isLoading)
                    ? () => runWithFeedback(
                          context,
                          ref,
                          () => ref.read(authProvider.notifier).signIn(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              ),
                          loadingProvider: loginLoadingProvider,
                          onSuccess: () => context.go('/home'),
                        )
                    : null,
              ),
              AppSpacing.vLarge,

              //lien vers l'inscription
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pas encore de compte? ',
                      style:
                          AppTextStyles.body.copyWith(color: AppColors.blackO)),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text('S\'inscrire',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
              AppSpacing.vLarge,

              //separateur et bouton google
              const OrDivider(),
              AppSpacing.vLarge,
              const GoogleSignInButton(),
            ],
          ),
        ),
      ),
    );
  }
}