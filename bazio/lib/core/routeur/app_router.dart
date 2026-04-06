import 'package:bazio/presentation/views/auth/login_view.dart';
import 'package:bazio/presentation/views/auth/register_view.dart';
import 'package:bazio/presentation/views/auth/email_verification_view.dart';
import 'package:bazio/presentation/views/home_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  //ce notifier ecoute les changements d etat firebase auth et previent le router
  refreshListenable: _AuthChangeNotifier(),

  redirect: (context, state) {
    final location = state.uri.toString();
    final user = FirebaseAuth.instance.currentUser;

    //firebase envoie parfois des liens d action par ici on les ignore
    if (location.contains('firebaseapp.com') ||
        location.contains('/__/auth/action')) {
      return '/login';
    }

    //pas de user connecte on bloque l acces au home et a la verification
    if (user == null) {
      if (location == '/home' || location == '/verify-email') {
        return '/login';
      }
      return null;
    }

    //google verifie lui meme l email donc pas besoin de notre verification
    final isGoogleAccount = user.providerData
        .any((p) => p.providerId == 'google.com');

    if (user.emailVerified || isGoogleAccount) {
      //user completement connecte on l empeche de retourner sur login/register
      if (location == '/login' || location == '/register') {
        return '/home';
      }
      return null;
    }

    //ici le user existe mais n a pas encore verifie son email on bloque le home
    if (location == '/home') {
      return '/verify-email';
    }

    return null;
  },

  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Page introuvable'),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => appRouter.go('/login'),
            child: const Text('Retour'),
          ),
        ],
      ),
    ),
  ),

  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterView(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) {
        //l email vient toujours de la page d inscription via state.extra
        final email = state.extra as String? ?? '';
        return EmailVerificationView(email: email);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeView(),
    ),
  ],
);

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    //previent le router de recalculer les redirections a chaque changement d auth
    FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }
}