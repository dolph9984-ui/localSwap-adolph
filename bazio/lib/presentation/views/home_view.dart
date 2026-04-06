import 'package:bazio/core/constants/colors.dart';
import 'package:bazio/core/constants/text_styles.dart';
import 'package:bazio/presentation/viewmodels/auth/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      //on remet le spinner Google a zero a l'arrivee sur home
      //car le widget GoogleSignInButton peut etre detruit avant que
      //runWithFeedback ait le temps de le faire lui meme
      ref.read(googleLoadingProvider.notifier).setValue(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bgB,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour 👋',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.blackO),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.displayName ?? user?.email ?? 'Utilisateur',
                        style: AppTextStyles.h2
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Text(
                            (user?.displayName ?? user?.email ?? 'U')[0]
                                .toUpperCase(),
                            style: AppTextStyles.bodyBold
                                .copyWith(color: Colors.white),
                          )
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.construction_rounded,
                        color: AppColors.primary, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Page provisoire',
                      style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'L\'application est en cours de développement. '
                      'Tu es bien connecté et l\'authentification fonctionne correctement.',
                      style: AppTextStyles.body.copyWith(color: AppColors.blackO),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  //logOut met state a null, authStateChanges le detecte
                  //et le router redirige automatiquement vers /login
                  onPressed: () => ref.read(authProvider.notifier).logOut(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD9D9D9)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.redAccent, size: 20),
                  label: Text(
                    'Se déconnecter',
                    style: AppTextStyles.bodyBold
                        .copyWith(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}