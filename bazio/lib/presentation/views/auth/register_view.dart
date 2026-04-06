import 'package:bazio/core/components/button_text.dart';
import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/input_decoration.dart';
import 'package:bazio/core/constants/spacing.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/core/utils.dart/auth_helpers.dart';
import 'package:bazio/core/utils.dart/validators.dart';
import 'package:bazio/presentation/viewmodels/auth/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;

  //variables locales pour les inputs
  String _name     = '';
  String _email    = '';
  String _password = '';
  String _confirm  = '';

  //validateur local pour eviter les problemes de timing des providers
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController     = TextEditingController();
    _emailController    = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController  = TextEditingController();

    for (final c in [
      _nameController,
      _emailController,
      _passwordController,
      _confirmController,
    ]) {
      c.addListener(_updateFormState);
    }

    //reset du state de chargement au montage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registerLoadingProvider.notifier).setValue(false);
    });
  }

  void _updateFormState() {
    setState(() {
      _name     = _nameController.text.trim();
      _email    = _emailController.text.trim();
      _password = _passwordController.text.trim();
      _confirm  = _confirmController.text.trim();

      //check global de validite via le helper
      _isFormValid =
          Validators.isValidName(_name) &&
          Validators.isValidEmail(_email) &&
          Validators.isValidPassword(_password) &&
          _confirm == _password;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isObscured        = ref.watch(obscureRegisterPasswordProvider);
    final isConfirmObscured = ref.watch(obscureConfirmPasswordProvider);
    final isLoading         = ref.watch(registerLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              Text('Inscription',
                  style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
              AppSpacing.vMedium,
              Text(
                'Crée ton compte pour acheter et\nvendre facilement autour de toi',
                textAlign: TextAlign.center,
                style: AppTextStyles.h3.copyWith(color: AppColors.blackO),
              ),
              AppSpacing.vExtraLarge,

              TextFormField(
                controller: _nameController,
                style: AppTextStyles.body,
                textInputAction: TextInputAction.next,
                decoration: AppInputDecoration.defaultStyle(
                  hint: 'Entrez votre nom complet',
                  label: 'Nom complet',
                  isEmpty: _name.isEmpty,
                  isValid: Validators.isValidName(_name),
                  errorText: _name.isNotEmpty && !Validators.isValidName(_name)
                      ? 'Lettres et espaces uniquement, min 3 caractères'
                      : null,
                ),
              ),
              AppSpacing.vLarge,

              TextFormField(
                controller: _emailController,
                style: AppTextStyles.body,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: AppInputDecoration.defaultStyle(
                  hint: 'Entrez votre adresse mail',
                  label: 'Adresse mail',
                  isEmpty: _email.isEmpty,
                  isValid: Validators.isValidEmail(_email),
                  errorText: _email.isNotEmpty && !Validators.isValidEmail(_email)
                      ? 'Adresse email invalide'
                      : null,
                ),
              ),
              AppSpacing.vLarge,

              TextFormField(
                controller: _passwordController,
                obscureText: isObscured,
                obscuringCharacter: '●',
                style: AppTextStyles.body,
                textInputAction: TextInputAction.next,
                decoration: AppInputDecoration.defaultStyle(
                  hint: '●●●●●●●●●●',
                  label: 'Mot de passe',
                  isEmpty: _password.isEmpty,
                  isValid: Validators.isValidPassword(_password),
                  errorText: _password.isNotEmpty
                      ? Validators.passwordError(_password)
                      : null,
                  suffixIcon: IconButton(
                    onPressed: () => ref
                        .read(obscureRegisterPasswordProvider.notifier)
                        .toggle(),
                    icon: SvgPicture.asset(
                      isObscured
                          ? 'assets/icones/eye_close.svg'
                          : 'assets/icones/eye_open.svg',
                      width: 24,
                      colorFilter: const ColorFilter.mode(
                          Colors.grey, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              AppSpacing.vLarge,

              TextFormField(
                controller: _confirmController,
                obscureText: isConfirmObscured,
                obscuringCharacter: '●',
                style: AppTextStyles.body,
                textInputAction: TextInputAction.done,
                decoration: AppInputDecoration.defaultStyle(
                  hint: '●●●●●●●●●●',
                  label: 'Confirmer votre mot de passe',
                  isEmpty: _confirm.isEmpty,
                  isValid: _confirm == _password && _confirm.isNotEmpty,
                  errorText: _confirm.isNotEmpty && _confirm != _password
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
                  suffixIcon: IconButton(
                    onPressed: () => ref
                        .read(obscureConfirmPasswordProvider.notifier)
                        .toggle(),
                    icon: SvgPicture.asset(
                      isConfirmObscured
                          ? 'assets/icones/eye_close.svg'
                          : 'assets/icones/eye_open.svg',
                      width: 24,
                      colorFilter: const ColorFilter.mode(
                          Colors.grey, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              AppSpacing.vExtraLarge,

              AppButton(
                text: 'S\'inscrire',
                isLoading: isLoading,
                onPressed: (_isFormValid && !isLoading)
                    ? () => runWithFeedback(
                          context,
                          ref,
                          () => ref.read(authProvider.notifier).signUp(
                                _nameController.text.trim(),
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              ),
                          loadingProvider: registerLoadingProvider,
                          onSuccess: () {
                            //save de l email pour le notifier avant de partir
                            ref
                                .read(pendingVerificationEmailProvider.notifier)
                                .set(_emailController.text.trim());

                            context.go(
                              '/verify-email',
                              extra: _emailController.text.trim(),
                            );
                          },
                        )
                    : null,
              ),

              AppSpacing.vLarge,

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Déjà un compte? ',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.blackO)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text('Se connecter',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
              AppSpacing.vLarge,

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

